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

    log_info("Starting HAML LSP (use_bundle: #{@use_bundle})")
  end

  def start
    loop do
      request = request_data
      break if request.nil?

      response = handle_request(request)
      send_response(response) if response
    end
  rescue StandardError => e
    log_error("Fatal error in LSP wrapper: #{e.message}")
    log_error(e.backtrace.join("\n"))
    exit(1)
  end

  private

  def header_content_length
    headers = {}

    loop do
      line = $stdin.gets
      return nil if line.nil?

      line = line.strip
      break if line.empty?

      key, value = line.split(": ", 2)
      headers[key] = value
    end

    headers.empty? ? nil : headers["Content-Length"].to_i
  end

  def request_data
    content_length = header_content_length
    return nil if content_length.nil?

    request_content = $stdin.read(content_length)
    JSON.parse(request_content)
  end

  def handle_request(request)
    method = request["method"]
    id = request["id"]

    case method
    when "initialize"
      handle_initialize(request, id)
    when "textDocument/didOpen", "textDocument/didChange", "textDocument/didSave"
      handle_did_change(request)
      nil
    when "shutdown"
      lsp_response_json(id: id, result: nil)
    when "exit"
      exit(0)
    end
  end

  def handle_initialize(request, id)
    params = request["params"]
    @root_uri = params["rootUri"]

    lsp_respond_to_initialize(id)
  end

  def handle_did_change(request)
    return unless enable_lint

    params = request["params"]
    id = request["id"]
    text_document = params["textDocument"]
    uri = text_document["uri"]

    file_path = URI.decode_uri_component(uri.sub("file://", ""))
    content = extract_content_from_request(request)
    diagnostics = linter.lint_file(file_path, content)

    lsp_respond_to_diagnostics(id, uri, diagnostics)
  end

  def extract_content_from_request(request)
    if request["method"] == "textDocument/didOpen"
      params["textDocument"]["text"]
    elsif request["method"] == "textDocument/didChange"
      # For full document sync, the last change contains the full text
      changes = params["contentChanges"]
      changes.last["text"] if changes && !changes.empty?
    end
  end
end
