# frozen_string_literal: true

module HamlLsp
  # In-memory store for documents
  class Store
    attr_reader :documents

    def initialize
      @documents = {}
    end

    def get(uri)
      @documents[uri]
    end

    def set(uri, content)
      return nil unless uri && content

      if @documents[uri]
        @documents[uri].update_content(content)
      else
        @documents[uri] = HamlLsp::Document.new(uri: uri, content: content)
      end

      @documents[uri]
    end

    def delete(uri)
      @documents.delete(uri)
      nil
    end

    def clear
      @documents.clear
    end

    def each(&)
      @documents.each_value(&)
    end
  end
end
