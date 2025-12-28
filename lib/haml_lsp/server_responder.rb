# frozen_string_literal: true

module HamlLsp
  # LSP-related utilities and helpers
  module ServerResponder
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

      HamlLsp::Message::Result.new(id: id, response: result)
    end

    def lsp_respond_to_shutdown(request)
      HamlLsp::Message::Result.new(id: request.id, response: nil)
    end

    def lsp_respond_to_diagnostics(uri, diagnostics)
      HamlLsp::Message::Notification.publish_diagnostics(uri, diagnostics)
    end

    def lsp_respond_to_formatting(id, formatted_content)
      response = [
        HamlLsp::Interface::TextEdit.new(
          range: full_content_range(formatted_content),
          new_text: formatted_content
        )
      ]

      HamlLsp::Message::Result.new(id: id, response: response)
    end

    def lsp_respond_to_completion(id, items)
      response = items.map do |item|
        HamlLsp::Interface::CompletionItem.new(
          label: item[:label],
          kind: item[:kind],
          detail: item[:detail],
          documentation: item[:documentation]
        )
      end

      HamlLsp::Message::Result.new(id: id, response: response)
    end

    def send_message(message)
      @writer.write(message.to_hash)
    end

    def send_log_message(message, type: HamlLsp::Constant::MessageType::LOG)
      send_message(HamlLsp::Message::Notification.window_log_message(message, type: type))
    end

    def send_log_message_error(message)
      send_log_message(message, type: HamlLsp::Constant::MessageType::ERROR)
    end

    def show_error_message(text)
      send_message(HamlLsp::Message::Notification.window_show_message(text, type: HamlLsp::Constant::MessageType::ERROR))
    end

    # returns a Range that covers the full content
    def full_content_range(content)
      line_count = content.lines.size
      last_line_length = content.lines.last&.chomp&.length || 0

      HamlLsp::Interface::Range.new(
        start: HamlLsp::Interface::Position.new(line: 0, character: 0),
        end: HamlLsp::Interface::Position.new(line: line_count, character: last_line_length)
      )
    end
  end
end
