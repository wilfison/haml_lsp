# frozen_string_literal: true

module HamlLsp
  # Server class to handle LSP requests
  class Server # rubocop:disable Metrics/ClassLength
    include HamlLsp::ServerResponder

    attr_reader :root_uri, :use_bundle, :enable_lint, :rails_routes_cache

    def initialize(use_bundle: false, enable_lint: false, root_uri: nil)
      @initialized = false
      @root_uri = URI.decode_uri_component(root_uri.sub("file://", "")) if root_uri
      @use_bundle = use_bundle
      @enable_lint = enable_lint
      @rails_routes_cache = nil

      load_rails_routes if rails_project?
    end

    def start
      send_log_message("Starting HAML LSP")
      send_log_message("    Use bundle: #{@use_bundle}")
      send_log_message("    Enable lint: #{@enable_lint}")
      send_log_message("    Root URI: #{@root_uri || "not set"}")

      HamlLsp.reader.each_message do |message|
        response_message = handle_request(message)
        next unless response_message

        send_message(response_message)
      rescue StandardError => e
        send_log_message_error("Fatal error (##{message.id}:#{message.method}): #{e.message}")
        send_log_message_error(e.backtrace.join("\n"))
        exit(1)
      end
    end

    private

    def store
      @store ||= HamlLsp::Store.new
    end

    def rails_project?
      @rails_project ||= HamlLsp::Rails::Detector.rails_project?(root_uri)
    end

    def handle_request(request) # rubocop:disable Metrics/CyclomaticComplexity
      case request.method
      when "initialize"
        handle_initialize(request)
      when "textDocument/didOpen", "textDocument/didChange", "textDocument/didSave"
        handle_did_change(request)
      when "textDocument/didClose"
        store.delete(request.document_uri)
      when "textDocument/formatting"
        handle_formatting(request)
      when "textDocument/completion"
        handle_completion(request)
      when "textDocument/definition"
        handle_definition(request)
      when "textDocument/codeAction"
        handle_code_action(request)
      when "codeAction/resolve"
        handle_code_action_resolve(request)
      when "shutdown"
        lsp_respond_to_shutdown(request)
      when "exit"
        exit(0)
      end
    rescue StandardError => e
      send_log_message_error("Error handling request #{request.method}: #{e.message}\n#{e.backtrace.join("\n")}")
      show_error_message("HAML LSP error: #{e.message}")
      nil
    end

    def handle_initialize(request)
      @root_uri = request.root_uri

      lsp_respond_to_initialize(request.id)
    end

    def handle_did_change(request)
      document = store.set(request.document_uri, request.document_content)

      return unless enable_lint

      content = request.document_content
      diagnostics = linter.lint_file(request.document_uri_path, content)

      # Save diagnostics in the document for code actions
      document&.update_diagnostics(diagnostics)

      lsp_respond_to_diagnostics(request.document_uri, diagnostics)
    end

    def handle_formatting(request)
      content = store.get(request.document_uri)&.content || ""
      return if content.empty?

      formatted_content = autocorrector.autocorrect(request.document_uri_path, content)
      lsp_respond_to_formatting(request.id, formatted_content)
    end

    def handle_completion(request)
      items = completion_provider.handle(request, rails_routes_cache)

      lsp_respond_to_completion(request.id, items)
    end

    def handle_definition(request)
      return lsp_respond_to_definition(request.id, []) unless rails_project?
      return lsp_respond_to_definition(request.id, []) if rails_routes_cache.nil? || rails_routes_cache.empty?

      document = store.get(request.document_uri)
      return lsp_respond_to_definition(request.id, []) unless document

      # Get the word at the current position
      word = HamlLsp::Utils.word_at_position(
        document.content,
        request.params.dig(:position, :line),
        request.params.dig(:position, :character)
      )

      # Find definition using the routes provider
      locations = HamlLsp::Definition::Routes.find_definition(word, rails_routes_cache, root_uri)

      send_log_message("Providing #{locations.size} definitions for #{word}: ##{request.id}")
      lsp_respond_to_definition(request.id, locations)
    end

    def handle_code_action(request)
      return lsp_respond_to_code_action(request.id, []) unless enable_lint

      document = store.get(request.document_uri)
      return lsp_respond_to_code_action(request.id, []) unless document

      # Get diagnostics from the context
      diagnostics = request.params.dig(:context, :diagnostics) || []

      # Convert raw diagnostics to our format and filter autocorrectable ones
      actions = []
      autocorrectable_diagnostics = autocorrector.autocorrectable_diagnostics(diagnostics)
      if autocorrectable_diagnostics.any?
        actions << {
          title: "Fix All Auto-correctable Issues",
          kind: HamlLsp::Constant::CodeActionKind::QUICK_FIX,
          diagnostics: autocorrectable_diagnostics,
          data: {
            uri: request.document_uri
          }
        }
      end

      send_log_message("Providing #{actions.size} code actions ##{request.id}")
      lsp_respond_to_code_action(request.id, actions)
    end

    def handle_code_action_resolve(request)
      data = request.params[:data]
      uri = data[:uri]

      document = store.get(uri)
      return lsp_respond_to_code_action_resolve(request.id, request.params) unless document

      # Get corrected content
      corrected_content = autocorrector.autocorrect(
        URI.parse(uri).path,
        document.content
      )

      # Create workspace edit
      edit = HamlLsp::Interface::WorkspaceEdit.new(
        changes: {
          uri => [
            HamlLsp::Interface::TextEdit.new(
              range: full_content_range(document.content),
              new_text: corrected_content
            )
          ]
        }
      )

      # Add edit to code action
      action = HamlLsp::Interface::CodeAction.new(
        title: request.params[:title],
        kind: request.params[:kind],
        diagnostics: request.params[:diagnostics],
        edit: edit
      )

      send_log_message("Autocorrected code action for #{uri}")
      lsp_respond_to_code_action_resolve(request.id, action)
    end

    def linter
      @linter ||= HamlLsp::Linter.new(root_uri: root_uri)
    end

    def autocorrector
      @autocorrector ||= Autocorrect::Base.new(linter: linter)
    end

    def completion_provider
      @completion_provider ||= HamlLsp::Completion::Provider.new(store: store, rails_project: rails_project?)
    end

    def load_rails_routes
      raise "No root URI set" unless root_uri

      @rails_routes_cache = HamlLsp::Rails::RoutesExtractor.extract_routes(root_uri)
      HamlLsp.log("Loaded #{@rails_routes_cache.keys.size} Rails routes for autocompletion")
    rescue StandardError => e
      warn("[haml-lsp] Error extracting Rails routes: #{e.message}")
      []
    end
  end
end
