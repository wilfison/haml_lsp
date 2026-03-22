# frozen_string_literal: true

module HamlLsp
  module References
    # Provider for textDocument/references
    class Provider
      PARTIAL_REGEXP = /render\s*\(?\s*(?:partial:)?\s*["']([^"']+)["']/

      # @param request [HamlLsp::Message::Request]
      # @param document [HamlLsp::Document]
      # @param root_uri [String, nil]
      # @return [Array<HamlLsp::Interface::Location>]
      def handle(request, document, root_uri)
        line_index = request.params.dig(:position, :line).to_i
        line = document.line_at_position(line_index)
        return [] unless line&.match?(/=\s*render/)

        partial_name = line.match(PARTIAL_REGEXP)&.captures&.first
        return [] if partial_name.nil? || partial_name.empty?

        find_references(partial_name, root_uri)
      end

      private

      def find_references(partial_name, root_uri)
        haml_files = find_haml_files(root_uri)
        locations = []

        haml_files.each do |file|
          content = File.read(file)
          content.lines.each_with_index do |line, line_index|
            match = line.match(PARTIAL_REGEXP)
            next unless match && match[1] == partial_name

            locations << HamlLsp::Interface::Location.new(
              uri: "file://#{file}",
              range: HamlLsp::Interface::Range.new(
                start: HamlLsp::Interface::Position.new(line: line_index, character: match.begin(1)),
                end: HamlLsp::Interface::Position.new(line: line_index, character: match.end(1))
              )
            )
          end
        end

        locations
      end

      def find_haml_files(root_uri)
        return [] unless root_uri

        Dir.glob(File.join(root_uri, "**", "*.haml"))
      end
    end
  end
end
