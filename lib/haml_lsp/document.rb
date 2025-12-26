# frozen_string_literal: true

module HamlLsp
  # In-memory store for documents
  class Document
    attr_reader :uri, :content

    def initialize(uri:, content:)
      @uri = uri
      @content = content
    end

    def update_content(new_content)
      @content = new_content
    end
  end
end
