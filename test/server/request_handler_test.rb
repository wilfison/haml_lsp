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

      def test_handle_initialized_without_server
        request = MockRequest.new(method: "initialized")

        result = @handler.handle(request)

        assert_nil result
      end

      def test_handle_initialized_with_server_non_rails
        mock_server = Minitest::Mock.new
        mock_server.expect(:register_file_watchers, nil)
        handler = HamlLsp::Server::RequestHandler.new(
          store: @store,
          cache_manager: @cache_manager,
          enable_lint: false,
          root_uri: nil,
          server: mock_server
        )

        request = MockRequest.new(method: "initialized")

        # Non-Rails project should not send progress notifications but should register watchers
        result = handler.handle(request)

        assert_nil result
        mock_server.verify
      end

      def test_handle_rescues_errors_and_returns_nil
        # Force a strategy that raises
        @store.set("file:///test.haml", "%h1 Hello")
        request = MockRequest.new(
          method: "textDocument/formatting",
          document_uri: "file:///crash.haml",
          params: { textDocument: { uri: "file:///crash.haml" } }
        )

        # Stub the autocorrector to raise
        bad_autocorrector = Object.new
        def bad_autocorrector.autocorrect(*, **)
          raise StandardError, "boom"
        end
        @handler.instance_variable_set(:@autocorrector, bad_autocorrector)
        @store.set("file:///crash.haml", "%h1 Hello")

        result = @handler.handle(request)

        assert_nil result
      end

      def test_handle_error_does_not_crash_subsequent_requests
        bad_autocorrector = Object.new
        def bad_autocorrector.autocorrect(*, **)
          raise StandardError, "boom"
        end
        @handler.instance_variable_set(:@autocorrector, bad_autocorrector)
        @store.set("file:///crash.haml", "%h1 Hello")

        crash_request = MockRequest.new(
          method: "textDocument/formatting",
          document_uri: "file:///crash.haml",
          params: { textDocument: { uri: "file:///crash.haml" } }
        )
        @handler.handle(crash_request)

        # Subsequent request should still work
        close_request = MockRequest.new(
          method: "textDocument/didClose",
          document_uri: "file:///crash.haml"
        )
        result = @handler.handle(close_request)

        assert_nil result
      end

      def test_handle_initialized_with_server_rails_project
        mock_server = Minitest::Mock.new
        cache_manager = HamlLsp::Server::CacheManager.new(root_uri: "/tmp/test")
        cache_manager.instance_variable_set(:@rails_project, true)

        handler = HamlLsp::Server::RequestHandler.new(
          store: @store,
          cache_manager: cache_manager,
          enable_lint: false,
          root_uri: "/tmp/test",
          server: mock_server
        )

        request = MockRequest.new(method: "initialized")

        mock_server.expect(:create_work_done_progress_token, nil) { |token| token.is_a?(String) }
        mock_server.expect(:send_progress_begin, nil) { true }
        mock_server.expect(:send_progress_report, nil) { true }
        mock_server.expect(:send_progress_end, nil) { |token| token.is_a?(String) }
        mock_server.expect(:register_file_watchers, nil)

        result = handler.handle(request)

        assert_nil result
        mock_server.verify
      end

      def test_did_change_watched_files_invalidates_routes
        routes_invalidated = false
        routes_reloaded = false
        @cache_manager.define_singleton_method(:invalidate_rails_routes) { routes_invalidated = true }
        @cache_manager.define_singleton_method(:load_rails_routes_async) { routes_reloaded = true }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: { changes: [{ uri: "file:///project/config/routes.rb", type: 2 }] }
        )

        @handler.handle(request)

        assert routes_invalidated, "Expected rails routes cache to be invalidated"
        assert routes_reloaded, "Expected rails routes async reload"
      end

      def test_did_change_watched_files_reloads_lint_config
        handler = HamlLsp::Server::RequestHandler.new(
          store: @store,
          cache_manager: @cache_manager,
          enable_lint: true,
          root_uri: nil
        )

        config_updated = false
        linter = handler.send(:linter)
        linter.define_singleton_method(:update_config) { config_updated = true }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: { changes: [{ uri: "file:///project/.haml-lint.yml", type: 2 }] }
        )

        handler.handle(request)

        assert config_updated, "Expected linter config to be updated"
      end

      def test_did_change_watched_files_ignores_lint_config_when_lint_disabled
        config_updated = false
        linter = @handler.send(:linter)
        linter.define_singleton_method(:update_config) { config_updated = true }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: { changes: [{ uri: "file:///project/.haml-lint.yml", type: 2 }] }
        )

        @handler.handle(request)

        refute config_updated, "Expected linter config NOT to be updated when lint disabled"
      end

      def test_did_change_watched_files_invalidates_partials
        partials_invalidated = false
        partials_reloaded = false
        @cache_manager.define_singleton_method(:invalidate_partials) { partials_invalidated = true }
        @cache_manager.define_singleton_method(:load_partials_async) { partials_reloaded = true }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: { changes: [{ uri: "file:///project/app/views/shared/_header.haml", type: 1 }] }
        )

        @handler.handle(request)

        assert partials_invalidated, "Expected partials cache to be invalidated"
        assert partials_reloaded, "Expected partials async reload"
      end

      def test_did_change_watched_files_ignores_unrelated_files
        routes_invalidated = false
        partials_invalidated = false
        @cache_manager.define_singleton_method(:invalidate_rails_routes) { routes_invalidated = true }
        @cache_manager.define_singleton_method(:invalidate_partials) { partials_invalidated = true }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: { changes: [{ uri: "file:///project/app/models/user.rb", type: 2 }] }
        )

        @handler.handle(request)

        refute routes_invalidated
        refute partials_invalidated
      end

      def test_did_change_watched_files_handles_multiple_changes
        routes_invalidated = false
        partials_invalidated = false
        @cache_manager.define_singleton_method(:invalidate_rails_routes) { routes_invalidated = true }
        @cache_manager.define_singleton_method(:load_rails_routes_async) { nil }
        @cache_manager.define_singleton_method(:invalidate_partials) { partials_invalidated = true }
        @cache_manager.define_singleton_method(:load_partials_async) { nil }

        request = MockRequest.new(
          method: "workspace/didChangeWatchedFiles",
          params: {
            changes: [
              { uri: "file:///project/config/routes.rb", type: 2 },
              { uri: "file:///project/app/views/shared/_nav.haml", type: 1 }
            ]
          }
        )

        @handler.handle(request)

        assert routes_invalidated, "Expected routes invalidated"
        assert partials_invalidated, "Expected partials invalidated"
      end
    end
  end
end
