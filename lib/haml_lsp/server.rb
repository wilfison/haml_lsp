# frozen_string_literal: true

# Server class to handle LSP requests
class HamlLsp::Server
  include HamlLsp::ServerResponder

  attr_reader :root_uri, :use_bundle, :enable_lint

  def initialize(use_bundle: false, enable_lint: false, root_uri: nil)
    @initialized = false
    @root_uri = URI.decode_uri_component(root_uri.sub("file://", "")) if root_uri
    @use_bundle = use_bundle
    @enable_lint = enable_lint

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
    when "shutdown"
      lsp_respond_to_shutdown(request)
    when "exit"
      exit(0)
    end
  end

  def handle_initialize(request)
    @root_uri = request.root_uri

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
end
