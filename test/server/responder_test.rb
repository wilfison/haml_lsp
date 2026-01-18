# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Server
    class ResponderTest < Minitest::Test
      class TestServer
        include HamlLsp::Server::Responder

        # Expose send_response for testing
        attr_reader :last_response

        def send_message(message)
          @last_response = message
        end
      end

      def setup
        @server = TestServer.new
      end

      def test_lsp_respond_to_initialize
        response = @server.lsp_respond_to_initialize(1)

        assert_instance_of HamlLsp::Message::Result, response
        assert_equal 1, response.id
        assert_instance_of LanguageServer::Protocol::Interface::InitializeResult, response.response
      end

      def test_lsp_respond_to_diagnostics
        diagnostics = []
        notification = @server.lsp_respond_to_diagnostics("file:///test.haml", diagnostics)

        assert_instance_of HamlLsp::Message::Notification, notification
        assert_equal "textDocument/publishDiagnostics", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::PublishDiagnosticsParams, notification.params
      end

      def test_show_error_message
        @server.show_error_message("Test error")

        notification = @server.last_response

        assert_instance_of HamlLsp::Message::Notification, notification
        assert_equal "window/showMessage", notification.method

        params = notification.params

        assert_instance_of LanguageServer::Protocol::Interface::ShowMessageParams, params
        assert_equal "Test error", params.attributes[:message]
        assert_equal LanguageServer::Protocol::Constant::MessageType::ERROR, params.attributes[:type]
      end

      def test_create_work_done_progress_token
        @server.create_work_done_progress_token("test-token")

        request = @server.last_response

        assert_instance_of HamlLsp::Message::Request, request
        assert_equal "window/workDoneProgress/create", request.method
      end

      def test_send_progress_begin
        @server.send_progress_begin("test-token", "Test Progress")

        notification = @server.last_response

        assert_instance_of HamlLsp::Message::Notification, notification
        assert_equal "$/progress", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::ProgressParams, notification.params
      end

      def test_send_progress_report
        @server.send_progress_report("test-token", message: "Working...", percentage: 50)

        notification = @server.last_response

        assert_instance_of HamlLsp::Message::Notification, notification
        assert_equal "$/progress", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::ProgressParams, notification.params
      end

      def test_send_progress_end
        @server.send_progress_end("test-token")

        notification = @server.last_response

        assert_instance_of HamlLsp::Message::Notification, notification
        assert_equal "$/progress", notification.method
        assert_instance_of LanguageServer::Protocol::Interface::ProgressParams, notification.params
      end
    end
  end
end
