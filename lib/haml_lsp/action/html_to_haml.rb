# frozen_string_literal: true

require "html2haml"

module HamlLsp
  module Action
    # Module to handle HTML/ERB to HAML conversion actions
    module HtmlToHaml
      class << self
        def action_items(request)
          # Check if there's a selection in the request
          selection_range = request.params[:range]
          return [] unless selection_range

          # Check if selection is not empty
          return [] if empty_selection?(selection_range)

          [
            {
              title: "Convert selected HTML/ERB to HAML",
              kind: HamlLsp::Constant::CodeActionKind::REFACTOR,
              data: {
                uri: request.document_uri,
                range: selection_range
              }
            }
          ]
        end

        def action_resolver_items(request, document)
          uri = request.params.dig(:data, :uri) || request.document_uri
          selection_range = request.params.dig(:data, :range)

          return nil unless selection_range && document.content

          # Extract the selected text
          selected_text = extract_text_from_range(document.content, selection_range)
          return nil if selected_text.empty?

          begin
            # Convert HTML/ERB to HAML
            haml_content = convert_to_haml(selected_text)

            # Create workspace edit
            edit = HamlLsp::Interface::WorkspaceEdit.new(
              changes: {
                uri => [
                  HamlLsp::Interface::TextEdit.new(
                    range: selection_range,
                    new_text: haml_content
                  )
                ]
              }
            )

            request.params.merge(edit: edit)
          rescue StandardError => e
            HamlLsp.log("Error converting HTML/ERB to HAML: #{e.message}")
            nil
          end
        end

        private

        def empty_selection?(range)
          start_line = range[:start][:line]
          start_char = range[:start][:character]
          end_line = range[:end][:line]
          end_char = range[:end][:character]

          start_line == end_line && start_char == end_char
        end

        def extract_text_from_range(content, range)
          lines = content.split("\n")
          start_line = range[:start][:line]
          start_char = range[:start][:character]
          end_line = range[:end][:line]
          end_char = range[:end][:character]

          if start_line == end_line
            lines[start_line][start_char...end_char] || ""
          else
            result = []
            # Add first line partial
            result << lines[start_line][start_char..] if start_line < lines.length
            # Add middle lines
            ((start_line + 1)...end_line).each { |i| result << lines[i] if i < lines.length }
            # Add last line partial
            result << lines[end_line][0...end_char] if end_line < lines.length
            result.join("\n")
          end
        end

        def convert_to_haml(html_content)
          # Use html2haml to convert
          ::Html2haml::HTML.new(html_content, erb: true).to_haml
        end
      end
    end
  end
end
