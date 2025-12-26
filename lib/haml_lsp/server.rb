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
      nil
    when "shutdown"
      lasp_respond_to_shutdown(request)
    when "exit"
      exit(0)
    end
  end

  def handle_initialize(request)
    @root_uri = request[:params][:rootUri]

    lsp_respond_to_initialize(request[:id])
  end

  def handle_did_change(request)
    return unless enable_lint

    params = request[:params]
    id = request[:id]
    uri = params[:textDocument][:uri]

    file_path = URI.decode_uri_component(uri.sub("file://", ""))
    content = extract_content_from_request(request)
    diagnostics = linter.lint_file(file_path, content)

    lsp_respond_to_diagnostics(id, uri, diagnostics)
  end

  def extract_content_from_request(request)
    if request[:method] == "textDocument/didOpen"
      request[:params][:textDocument][:text]
    elsif request[:method] == "textDocument/didChange"
      # For full document sync, the last change contains the full text
      changes = request[:params][:contentChanges]
      changes.last[:text] if changes && !changes.empty?
    end
  end
end
