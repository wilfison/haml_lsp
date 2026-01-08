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

    # Extract word from document content at the current position
    #
    # @param line [Integer] The line number (0-based)
    # @param character [Integer] The character position (0-based)
    # @return [String, nil] The line content up to the character position
    def word_at_position(line, character)
      HamlLsp::Utils.word_at_position(content, line, character)
    end

    # Extract line from document content at the current position
    #
    # @param line [Integer] The line number (0-based)
    # @param character [Integer] The character position (0-based)
    # @return [String, nil] The line content up to the character position
    def line_at_position(line)
      HamlLsp::Utils.line_at_position(content, line)
    end
  end
end
