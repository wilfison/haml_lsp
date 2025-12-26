# frozen_string_literal: true

require "test_helper"

module HamlLsp
  class ServerResponderTest < Minitest::Test
    class TestServer
      include HamlLsp::ServerResponder

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
      @server.lsp_respond_to_initialize(1)

      response = @server.last_response

      assert_instance_of LanguageServer::Protocol::Interface::ResponseMessage, response
      assert_equal 1, response.attributes[:id]
      assert_instance_of LanguageServer::Protocol::Interface::InitializeResult, response.attributes[:result]
    end

    def test_lsp_respond_to_diagnostics
      diagnostics = []
      @server.lsp_respond_to_diagnostics("file:///test.haml", diagnostics)

      notification = @server.last_response

      assert_instance_of LanguageServer::Protocol::Interface::NotificationMessage, notification
      assert_equal "textDocument/publishDiagnostics", notification.attributes[:method]
      assert_instance_of LanguageServer::Protocol::Interface::PublishDiagnosticsParams, notification.attributes[:params]
    end

    def test_show_error_message
      @server.show_error_message("Test error")

      notification = @server.last_response

      assert_instance_of LanguageServer::Protocol::Interface::NotificationMessage, notification
      assert_equal "window/showMessage", notification.attributes[:method]

      params = notification.attributes[:params]

      assert_instance_of LanguageServer::Protocol::Interface::ShowMessageParams, params
      assert_equal "Test error", params.attributes[:message]
      assert_equal LanguageServer::Protocol::Constant::MessageType::ERROR, params.attributes[:type]
    end
  end
end
