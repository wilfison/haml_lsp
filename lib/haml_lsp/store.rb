# frozen_string_literal: true

module HamlLsp
  # In-memory store for documents
  class Store
    def initialize
      @documents = {}
    end

    def get(uri)
      @documents[uri]
    end

    def set(uri, content)
      @documents[uri] = HamlLsp::Document.new(uri: uri, content: content)
    end

    def delete(uri)
      @documents.delete(uri)
    end

    def clear
      @documents.clear
    end

    def each(&)
      @documents.each_value(&)
    end
  end
end
