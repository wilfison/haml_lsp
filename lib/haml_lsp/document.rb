# frozen_string_literal: true

module HamlLsp
  # In-memory store for documents
  class Document
    attr_reader :uri, :content, :diagnostics

    def initialize(uri:, content:)
      @uri = uri
      @content = content
      @diagnostics = []
    end

    def update_content(new_content)
      @content = new_content
    end

    def update_diagnostics(new_diagnostics)
      @diagnostics = new_diagnostics || []
    end
  end
end
