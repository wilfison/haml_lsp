# frozen_string_literal: true

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

      @reader = HamlLsp::MessageReader.new($stdin)
      @writer = HamlLsp::MessageWriter.new($stdout)

      log_info("Starting HAML LSP (use_bundle: #{@use_bundle})")
    end

    def start
      @reader.each_message do |message|
        response_message = handle_request(message)
        send_message(response_message) if response_message
      end
    rescue StandardError => e
      log_error("Fatal error in LSP wrapper: #{e.message}")
      log_error(e.backtrace.join("\n"))
      exit(1)
    end

    private

    def handle_request(request)
      case request[:method]
      when "initialize"
        handle_initialize(request)
      when "textDocument/didOpen", "textDocument/didChange", "textDocument/didSave"
        handle_did_change(request)
      when "textDocument/formatting"
        handle_formatting(request)
      when "textDocument/completion"
        handle_completion(request)
      when "shutdown"
        lsp_respond_to_shutdown(request)
      when "exit"
        exit(0)
      end
    end

    def handle_initialize(request)
      @root_uri = request.root_uri
      @is_rails_project = HamlLsp::Rails::Detector.rails_project?(root_uri) if root_uri

      lsp_respond_to_initialize(request.id)
    end

    def handle_did_change(request)
      return unless enable_lint

      content = request.document_content
      diagnostics = linter.lint_file(request.document_uri_path, content)

      lsp_respond_to_diagnostics(
        request.id,
        request.document_uri,
        diagnostics
      )
    end

    def handle_formatting(request)
      content = request.document_content
      formatted_content = linter.format_file(request.document_uri_path, content)

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

    def linter
      @linter ||= HamlLsp::Linter.new(root_uri: root_uri)
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
