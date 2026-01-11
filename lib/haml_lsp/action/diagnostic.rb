# frozen_string_literal: true

module HamlLsp
  module Action
    # Module to handle diagnostics related actions
    module Diagnostic
      class << self
        def action_items(request)
          # Get diagnostics from the context
          diagnostics = request.params.dig(:context, :diagnostics) || []
          return [] unless diagnostics.any?

          # Convert raw diagnostics to our format and filter autocorrectable ones
          autocorrectable_diagnostics = HamlLsp::Autocorrect::Base.autocorrectable_diagnostics(diagnostics)
          return [] unless autocorrectable_diagnostics.any?

          [
            {
              title: "Fix All Auto-correctable Issues",
              kind: HamlLsp::Constant::CodeActionKind::QUICK_FIX,
              diagnostics: autocorrectable_diagnostics,
              data: {
                uri: request.document_uri
              }
            }
          ]
        end

        def action_resolver_items(request, document, autocorrector)
          uri = request.params.dig(:data, :uri) || request.document_uri

          # Get corrected content
          corrected_content = autocorrector.autocorrect(
            uri,
            document.content
          )

          # Create workspace edit
          edit = HamlLsp::Interface::WorkspaceEdit.new(
            changes: {
              uri => [
                HamlLsp::Interface::TextEdit.new(
                  range: HamlLsp::Utils.full_content_range(document.content),
                  new_text: corrected_content
                )
              ]
            }
          )

          # Add edit to code action
          HamlLsp::Interface::CodeAction.new(
            title: request.params[:title],
            kind: request.params[:kind],
            diagnostics: request.params[:diagnostics],
            edit: edit
          )
        end
      end
    end
  end
end
