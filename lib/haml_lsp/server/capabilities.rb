# frozen_string_literal: true

module HamlLsp
  module Server
    # Defines the server capabilities
    module Capabilities
      def self.server_capabilities
        HamlLsp::Interface::ServerCapabilities.new(
          text_document_sync: HamlLsp::Interface::TextDocumentSyncOptions.new(
            open_close: true,
            change: HamlLsp::Constant::TextDocumentSyncKind::FULL,
            save: HamlLsp::Interface::SaveOptions.new(include_text: true)
          ),
          document_formatting_provider: HamlLsp::Interface::DocumentFormattingOptions.new(
            work_done_progress: false
          ),
          completion_provider: HamlLsp::Interface::CompletionOptions.new(
            trigger_characters: ["_", ":", ".", "%", "#", '"', "'", "("],
            resolve_provider: false
          ),
          code_action_provider: HamlLsp::Interface::CodeActionOptions.new(
            code_action_kinds: [
              HamlLsp::Constant::CodeActionKind::QUICK_FIX
            ],
            resolve_provider: true
          ),
          definition_provider: true
        )
      end
    end
  end
end
