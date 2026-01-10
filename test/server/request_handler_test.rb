# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Server
    class RequestHandlerTest < Minitest::Test
      def setup
        @store = HamlLsp::Store.new
        @cache_manager = HamlLsp::Server::CacheManager.new(root_uri: nil)
        @handler = HamlLsp::Server::RequestHandler.new(
          store: @store,
          cache_manager: @cache_manager,
          enable_lint: false,
          root_uri: nil
        )
      end

      def test_handler_initializes_with_dependencies
        assert_instance_of HamlLsp::Server::RequestHandler, @handler
      end

      def test_handle_returns_nil_for_unknown_method
        request = MockRequest.new(method: "unknown/method")

        result = @handler.handle(request)

        assert_nil result
      end

      def test_handle_delegates_to_strategy
        request = MockRequest.new(
          method: "textDocument/didClose",
          document_uri: "file:///test.haml"
        )

        result = @handler.handle(request)

        assert_nil result
      end

      def test_handler_with_enable_lint
        handler = HamlLsp::Server::RequestHandler.new(
          store: @store,
          cache_manager: @cache_manager,
          enable_lint: true,
          root_uri: nil
        )

        request = MockRequest.new(
          method: "textDocument/didOpen",
          document_uri: "file:///test.haml",
          document_content: ".test",
          document_uri_path: "/test.haml"
        )

        result = handler.handle(request)

        assert_kind_of HamlLsp::Message::Notification, result
      end
    end
  end
end
