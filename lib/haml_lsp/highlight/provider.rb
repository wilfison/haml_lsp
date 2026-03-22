# frozen_string_literal: true

module HamlLsp
  module Highlight
    # Provider for textDocument/documentHighlight
    class Provider
      PARTIAL_REGEXP = /render\s*\(?\s*(?:partial:)?\s*["']([^"']+)["']/

      # @param request [HamlLsp::Message::Request]
      # @param document [HamlLsp::Document]
      # @return [Array<HamlLsp::Interface::DocumentHighlight>]
      def handle(request, document)
        line_index = request.params.dig(:position, :line).to_i
        line = document.line_at_position(line_index)
        return [] unless line&.match?(/=\s*render/)

        partial_name = line.match(PARTIAL_REGEXP)&.captures&.first
        return [] if partial_name.nil? || partial_name.empty?

        find_highlights(document, partial_name)
      end

      private

      def find_highlights(document, partial_name)
        highlights = []
        lines = document.content.to_s.lines

        lines.each_with_index do |line, line_index|
          match = line.match(PARTIAL_REGEXP)
          next unless match && match[1] == partial_name

          start_char = match.begin(1)
          end_char = match.end(1)

          highlights << HamlLsp::Interface::DocumentHighlight.new(
            range: HamlLsp::Interface::Range.new(
              start: HamlLsp::Interface::Position.new(line: line_index, character: start_char),
              end: HamlLsp::Interface::Position.new(line: line_index, character: end_char)
            ),
            kind: HamlLsp::Constant::DocumentHighlightKind::READ
          )
        end

        highlights
      end
    end
  end
end
