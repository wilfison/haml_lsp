# frozen_string_literal: true

module HamlLsp
  # LSP-related utilities and helpers
  module ServerResponder # rubocop:disable Metrics/ModuleLength
    def lsp_server_capabilities
      HamlLsp::Interface::ServerCapabilities.new(
        text_document_sync: HamlLsp::Interface::TextDocumentSyncOptions.new(
          open_close: true,
          change: HamlLsp::Constant::TextDocumentSyncKind::FULL,
          save: HamlLsp::Interface::SaveOptions.new(include_text: false)
        ),
        document_formatting_provider: HamlLsp::Interface::DocumentFormattingOptions.new(
          work_done_progress: false
        ),
        completion_provider: HamlLsp::Interface::CompletionOptions.new(
          trigger_characters: ["_"],
          resolve_provider: false
        )
      )
    end

    def lsp_respond_to_initialize(id)
      result = HamlLsp::Interface::InitializeResult.new(
        capabilities: lsp_server_capabilities,
        server_info: {
          name: "haml_lsp",
          version: HamlLsp::VERSION
        }
      )

      message = HamlLsp::Interface::ResponseMessage.new(
        jsonrpc: "2.0",
        id: id,
        result: result
      )

      send_message(message)
    end

    def lsp_respond_to_shutdown(request)
      HamlLsp::Interface::ResponseMessage.new(
        jsonrpc: "2.0",
        id: request.id,
        result: nil
      )
    end

    def lsp_respond_to_diagnostics(uri, diagnostics)
      params = HamlLsp::Interface::PublishDiagnosticsParams.new(
        uri: uri,
        diagnostics: diagnostics
      )

      notification = HamlLsp::Interface::NotificationMessage.new(
        jsonrpc: "2.0",
        method: "textDocument/publishDiagnostics",
        params: params
      )

      send_message(notification)
    end

    def lsp_respond_to_formatting(id, formatted_content)
      message = HamlLsp::Interface::ResponseMessage.new(
        jsonrpc: "2.0",
        id: id,
        result: [
          HamlLsp::Interface::TextEdit.new(
            range: HamlLsp::Interface::Range.new(
              start: HamlLsp::Interface::Position.new(line: 0, character: 0),
              end: HamlLsp::Interface::Position.new(line: Float::INFINITY, character: Float::INFINITY)
            ),
            new_text: formatted_content
          )
        ]
      )

      send_message(message)
    end

    def lsp_respond_to_completion(id, items)
      result = items.map do |item|
        HamlLsp::Interface::CompletionItem.new(
          label: item[:label],
          kind: item[:kind],
          detail: item[:detail],
          documentation: item[:documentation]
        )
      end

      message = HamlLsp::Interface::ResponseMessage.new(
        jsonrpc: "2.0",
        id: id,
        result: result
      )

      send_message(message)
    end

    def send_message(message)
      @writer.write(message)
    end

    def log_info(message)
      return if ENV["HAML_LSP_LOG_LEVEL"] == "fatal"

      warn("[haml-lsp] INFO: #{message}")
    end

    def log_error(message)
      warn("[haml-lsp] ERROR: #{message}")
    end

    def show_error_message(message)
      params = HamlLsp::Interface::ShowMessageParams.new(
        type: HamlLsp::Constant::MessageType::ERROR,
        message: message
      )

      notification = HamlLsp::Interface::NotificationMessage.new(
        jsonrpc: "2.0",
        method: "window/showMessage",
        params: params
      )

      send_message(notification)
    end
  end
end
