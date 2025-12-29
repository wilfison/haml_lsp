# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Message
    class MessageClassesTest < Minitest::Test
      def test_result_initialization
        result = HamlLsp::Message::Result.new(id: 1, response: "test")

        assert_equal 1, result.id
        assert_equal "test", result.response
      end

      def test_result_to_hash
        result = HamlLsp::Message::Result.new(id: 1, response: "test")
        hash = result.to_hash

        assert_equal({ id: 1, result: "test" }, hash)
      end

      def test_notification_window_show_message
        notification = HamlLsp::Message::Notification.window_show_message("Test message")

        assert_equal "window/showMessage", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::ShowMessageParams, notification.params
        assert_equal "Test message", notification.params.attributes[:message]
        assert_equal HamlLsp::Constant::MessageType::INFO, notification.params.attributes[:type]
      end

      def test_notification_window_show_message_with_error_type
        notification = HamlLsp::Message::Notification.window_show_message(
          "Error message",
          type: HamlLsp::Constant::MessageType::ERROR
        )

        assert_equal HamlLsp::Constant::MessageType::ERROR, notification.params.attributes[:type]
      end

      def test_notification_window_log_message
        notification = HamlLsp::Message::Notification.window_log_message("Log message")

        assert_equal "window/logMessage", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::LogMessageParams, notification.params
        assert_equal "[Haml LSP] Log message", notification.params.attributes[:message]
        assert_equal HamlLsp::Constant::MessageType::LOG, notification.params.attributes[:type]
      end

      def test_notification_telemetry
        data = { event: "test", value: 123 }
        notification = HamlLsp::Message::Notification.telemetry(data)

        assert_equal "telemetry/event", notification.method
        assert_equal data, notification.params
      end

      def test_notification_publish_diagnostics
        diagnostics = []
        notification = HamlLsp::Message::Notification.publish_diagnostics("file:///test.haml", diagnostics)

        assert_equal "textDocument/publishDiagnostics", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::PublishDiagnosticsParams, notification.params
        assert_equal "file:///test.haml", notification.params.attributes[:uri]
        assert_equal diagnostics, notification.params.attributes[:diagnostics]
      end

      def test_notification_to_hash
        notification = HamlLsp::Message::Notification.window_show_message("Test")
        hash = notification.to_hash

        assert_equal "window/showMessage", hash[:method]
        assert hash.key?(:params)
      end

      def test_notification_to_hash_without_params
        notification = HamlLsp::Message::Notification.new(method: "test/method", params: nil)
        hash = notification.to_hash

        assert_equal "test/method", hash[:method]
        refute hash.key?(:params)
      end

      def test_request_initialization
        request = HamlLsp::Message::Request.new(id: 1, method: "test/method", params: { key: "value" })

        assert_equal 1, request.id
        assert_equal "test/method", request.method
        assert_equal({ key: "value" }, request.params)
      end

      def test_writer_writes_json_with_content_length
        io = StringIO.new
        writer = HamlLsp::Message::Writer.new(io)
        message = { method: "test", params: {} }

        writer.write(message)

        output = io.string

        assert_includes output, "Content-Length:"
        assert_includes output, '"jsonrpc":"2.0"'
        assert_includes output, '"method":"test"'
      end

      def test_writer_adds_jsonrpc_field
        io = StringIO.new
        writer = HamlLsp::Message::Writer.new(io)
        message = { method: "test" }

        writer.write(message)

        output = io.string

        assert_includes output, '"jsonrpc":"2.0"'
      end

      def test_reader_initialization
        io = StringIO.new
        reader = HamlLsp::Message::Reader.new(io)

        assert_instance_of HamlLsp::Message::Reader, reader
      end
    end
  end
end
