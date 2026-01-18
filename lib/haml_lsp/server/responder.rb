# frozen_string_literal: true

module HamlLsp
  module Server
    # LSP-related utilities and helpers
    module Responder
      def lsp_respond_to_initialize(id)
        result = HamlLsp::Interface::InitializeResult.new(
          capabilities: HamlLsp::Server::Capabilities.server_capabilities,
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
            range: HamlLsp::Utils.full_content_range(formatted_content),
            new_text: formatted_content
          )
        ]

        HamlLsp::Message::Result.new(id: id, response: response)
      end

      def lsp_respond_to_completion(id, items)
        response = items.map do |item|
          HamlLsp::Interface::CompletionItem.new(**item)
        end

        HamlLsp::Message::Result.new(id: id, response: response)
      end

      def lsp_respond_to_code_action(id, actions)
        response = actions.map do |action|
          HamlLsp::Interface::CodeAction.new(
            title: action[:title],
            kind: action[:kind],
            diagnostics: action[:diagnostics],
            data: action[:data]
          )
        end

        HamlLsp::Message::Result.new(id: id, response: response)
      end

      def lsp_respond_to_code_action_resolve(id, action)
        HamlLsp::Message::Result.new(id: id, response: action)
      end

      def lsp_respond_to_definition(id, locations)
        # Return nil if no locations found, otherwise return array of Location objects
        response = locations.empty? ? nil : locations
        HamlLsp::Message::Result.new(id: id, response: response)
      end

      def send_message(message)
        HamlLsp.writer.write(message.to_hash)
      end

      def show_error_message(text)
        send_message(HamlLsp::Message::Notification.window_show_message(text, type: HamlLsp::Constant::MessageType::ERROR))
      end

      def create_work_done_progress_token(id)
        request = HamlLsp::Message::Request.new(
          id: id,
          method: "window/workDoneProgress/create",
          params: { token: id }
        )
        send_message(request)
      end

      def send_progress_begin(token, title, message: nil, percentage: nil)
        notification = HamlLsp::Message::Notification.progress_begin(
          token, title, message: message, percentage: percentage
        )
        send_message(notification)
      end

      def send_progress_report(token, message: nil, percentage: nil)
        send_message(HamlLsp::Message::Notification.progress_report(token, message: message, percentage: percentage))
      end

      def send_progress_end(token)
        send_message(HamlLsp::Message::Notification.progress_end(token))
      end
    end
  end
end
