# frozen_string_literal: true

module HamlLsp
  # In-memory store for documents with TTL and size limits to prevent memory leaks
  class Store
    attr_reader :documents
    attr_accessor :max_documents, :ttl_seconds

    # Default TTL: 1 hour (3600 seconds) for inactive documents
    DEFAULT_TTL = 3600
    # Default max documents: 1000
    DEFAULT_MAX_DOCUMENTS = 1000

    def initialize(max_documents: DEFAULT_MAX_DOCUMENTS, ttl_seconds: DEFAULT_TTL)
      @documents = {}
      @access_times = {}
      @max_documents = max_documents
      @ttl_seconds = ttl_seconds
    end

    def get(uri)
      document = @documents[uri]
      update_access_time(uri) if document
      document
    end

    def set(uri, content)
      return nil unless uri && content

      # Clean up before adding if we're at capacity
      cleanup_if_needed

      if @documents[uri]
        @documents[uri].update_content(content)
      else
        @documents[uri] = HamlLsp::Document.new(uri: uri, content: content)
      end

      update_access_time(uri)
      @documents[uri]
    end

    def delete(uri)
      @documents.delete(uri)
      @access_times.delete(uri)
      nil
    end

    def clear
      @documents.clear
      @access_times.clear
    end

    def each(&)
      @documents.each_value(&)
    end

    # Remove documents that haven't been accessed within TTL
    def cleanup_stale_documents
      now = Time.now
      stale_uris = @access_times.select { |_uri, time| now - time > @ttl_seconds }.keys

      stale_uris.each do |uri|
        delete(uri)
      end

      stale_uris.size
    end

    # Get document count
    def size
      @documents.size
    end

    private

    def update_access_time(uri)
      @access_times[uri] = Time.now
    end

    def cleanup_if_needed
      return unless @documents.size >= @max_documents

      # First try removing stale documents
      removed = cleanup_stale_documents

      # If still at capacity, remove least recently accessed document
      return unless @documents.size >= @max_documents && removed.zero?

      lru_uri = @access_times.min_by { |_uri, time| time }&.first
      return unless lru_uri

      delete(lru_uri)
    end
  end
end
