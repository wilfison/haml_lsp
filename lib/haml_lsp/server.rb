# frozen_string_literal: true

require "ostruct"

module HamlLsp
  # Server class to handle LSP requests
  class Server
    include HamlLsp::ServerResponder

    attr_reader :root_uri, :use_bundle, :enable_lint, :is_rails_project

    def initialize(use_bundle: false, enable_lint: false, root_uri: nil)
      @initialized = false
      @root_uri = URI.decode_uri_component(root_uri.sub("file://", "")) if root_uri
      @use_bundle = use_bundle
      @enable_lint = enable_lint
      @is_rails_project = false
      @rails_routes_cache = nil

      @reader = HamlLsp::Message::Reader.new($stdin)
      @writer = HamlLsp::Message::Writer.new($stdout)

      send_log_message("Starting HAML LSP")
      send_log_message("    Use bundle: #{@use_bundle}")
      send_log_message("    Enable lint: #{@enable_lint}")
      send_log_message("    Root URI: #{@root_uri || "not set"}")
    end

    def start
      @reader.each_message do |message|
        response_message = handle_request(message)
        send_message(response_message) if response_message
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

    def handle_request(request) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/MethodLength
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
      @is_rails_project = HamlLsp::Rails::Detector.rails_project?(root_uri) if root_uri

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
      items = []

      # Add HAML tags and attributes completions
      items += HamlLsp::Haml::TagsProvider.completion_items
      items += HamlLsp::Haml::AttributesProvider.completion_items

      # Add Rails routes if in a Rails project
      items += rails_routes if is_rails_project

      lsp_respond_to_completion(request.id, items)
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

      send_log_message("Providing #{actions.size} code actions for #{request.document_uri}")
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
      @autocorrector ||= HamlLsp::Autocorrector.new(
        root_uri: root_uri,
        config_file: linter.config_file
      )
    end

    def rails_routes
      @rails_routes ||= begin
        raise "No root URI set" unless root_uri

        HamlLsp::Rails::RoutesExtractor.extract_routes(root_uri)
      rescue StandardError => e
        warn("[haml-lsp] Error extracting Rails routes: #{e.message}")
        []
      end
    end
  end
end
