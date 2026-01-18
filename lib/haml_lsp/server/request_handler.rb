# frozen_string_literal: true

module HamlLsp
  module Server
    # Request handler with strategy pattern for different request types
    class RequestHandler
      include HamlLsp::Server::Responder

      def initialize(store:, cache_manager:, enable_lint: false, root_uri: nil, server: nil)
        @store = store
        @cache_manager = cache_manager
        @enable_lint = enable_lint
        @root_uri = root_uri
        @server = server
      end

      def handle(request)
        strategy = strategy_for(request.method)
        return nil unless strategy

        strategy.call(request)
      rescue StandardError => e
        HamlLsp.log("Error handling request #{request.method}: #{e.message}\n#{e.backtrace.join("\n")}")
        show_error_message("HAML LSP error: #{e.message}")
        nil
      end

      private

      def strategy_for(method)
        strategies[method]
      end

      def strategies
        @strategies ||= {
          "initialize" => method(:handle_initialize),
          "initialized" => method(:handle_initialized),
          "textDocument/didOpen" => method(:handle_did_change),
          "textDocument/didChange" => method(:handle_did_change),
          "textDocument/didSave" => method(:handle_did_change),
          "textDocument/didClose" => method(:handle_did_close),
          "textDocument/formatting" => method(:handle_formatting),
          "textDocument/completion" => method(:handle_completion),
          "textDocument/definition" => method(:handle_definition),
          "textDocument/codeAction" => method(:handle_code_action),
          "codeAction/resolve" => method(:handle_code_action_resolve),
          "shutdown" => method(:handle_shutdown),
          "exit" => method(:handle_exit)
        }
      end

      def handle_initialize(request)
        lsp_respond_to_initialize(request.id)
      end

      def handle_initialized(_request)
        return nil unless @server

        progress_token = "haml-lsp-init-#{Time.now.to_i}"
        @server.create_work_done_progress_token(progress_token)

        @server.send_progress_begin(progress_token, "Initializing HAML LSP")

        if @cache_manager.rails_project?
          @server.send_progress_report(progress_token, message: "Loading Rails routes...", percentage: 50)
          @cache_manager.rails_routes
        end

        @server.send_progress_end(progress_token)

        nil
      end

      def handle_did_change(request)
        return unless @enable_lint

        document = @store.set(request.document_uri, request.document_content)
        content = request.document_content
        return if content.nil? || content.empty?

        diagnostics = linter.lint_file(request.document_uri_path, content)

        # Save diagnostics in the document for code actions
        document&.update_diagnostics(diagnostics)

        lsp_respond_to_diagnostics(request.document_uri, diagnostics)
      end

      def handle_did_close(request)
        @store.delete(request.document_uri)
        nil
      end

      def handle_formatting(request)
        content = @store.get(request.document_uri)&.content || ""
        return if content.empty?

        formatted_content = autocorrector.autocorrect(request.document_uri_path, content)
        lsp_respond_to_formatting(request.id, formatted_content)
      end

      def handle_completion(request)
        items = completion_provider.handle(
          request,
          @cache_manager.rails_routes,
          @root_uri
        )

        HamlLsp.log("##{request.id}: Providing #{items.size} completion items")
        lsp_respond_to_completion(request.id, items)
      end

      def handle_definition(request)
        document = @store.get(request.document_uri)
        return lsp_respond_to_definition(request.id, []) unless document

        locations = definition_provider.handle(
          request,
          @cache_manager.rails_routes,
          @root_uri
        )

        HamlLsp.log("##{request.id}: Providing #{locations.size} definitions")
        lsp_respond_to_definition(request.id, locations)
      end

      def handle_code_action(request)
        document = @store.get(request.document_uri)
        return lsp_respond_to_code_action(request.id, []) unless document

        actions = action_provider.handle_request(request, enable_lint: @enable_lint)

        HamlLsp.log("##{request.id}: Providing #{actions.size} code actions")
        lsp_respond_to_code_action(request.id, actions)
      end

      def handle_code_action_resolve(request)
        uri = request.params[:data][:uri]

        document = @store.get(uri)
        return lsp_respond_to_code_action_resolve(request.id, request.params) unless document

        # Add edit to code action
        action = action_provider.handle_resolve(request, document, autocorrector)

        lsp_respond_to_code_action_resolve(request.id, action)
      end

      def handle_shutdown(request)
        HamlLsp::Message::Result.new(id: request.id, response: nil)
      end

      def handle_exit(_request)
        exit(0)
      end

      def linter
        @linter ||= HamlLsp::Linter.new(root_uri: @root_uri)
      end

      def autocorrector
        @autocorrector ||= Autocorrect::Base.new(linter: linter)
      end

      def action_provider
        @action_provider ||= HamlLsp::Action::Provider.new
      end

      def completion_provider
        @completion_provider ||= HamlLsp::Completion::Provider.new(
          store: @store,
          rails_project: @cache_manager.rails_project?
        )
      end

      def definition_provider
        @definition_provider ||= HamlLsp::Definition::Provider.new(
          store: @store,
          rails_project: @cache_manager.rails_project?
        )
      end
    end
  end
end
