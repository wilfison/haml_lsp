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

    # Apply incremental text changes from LSP contentChanges
    # @param changes [Array<Hash>] List of content changes with :range and :text
    def apply_changes(changes)
      changes.each do |change|
        if change[:range]
          apply_incremental_change(change[:range], change[:text])
        else
          @content = change[:text]
        end
      end
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

    private

    def apply_incremental_change(range, text)
      lines = @content.lines
      lines << "" if lines.empty?

      start_line = range[:start][:line]
      start_char = range[:start][:character]
      end_line = range[:end][:line]
      end_char = range[:end][:character]

      # Build prefix (before the change) and suffix (after the change)
      prefix = (lines[start_line] || "")[0...start_char] || ""
      suffix = (lines[end_line] || "")[end_char..] || ""

      # Replace the affected lines with the new text
      new_lines = "#{prefix}#{text}#{suffix}".lines
      new_lines = [""] if new_lines.empty?

      lines[start_line..end_line] = new_lines
      @content = lines.join
    end
  end
end
