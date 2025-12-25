# frozen_string_literal: true

# LSP-related utilities and helpers
module HamlLsp::ServerResponder
  LSP_CAPABILITIES = {
    textDocumentSync: {
      openClose: true,
      change: 1, # Full document sync
      save: { includeText: false }
    }
  }.freeze

  def lsp_respond_to_initialize(id)
    response = lsp_response_json(
      id: id,
      result: {
        capabilities: LSP_CAPABILITIES,
        serverInfo: {
          name: HamlLsp.lsp_name,
          version: HamlLsp::VERSION
        }
      }
    )

    send_response(response)
  end

  def lsp_respond_to_diagnostics(id, uri, diagnostics)
    response = lsp_response_json(
      id: id,
      method: "textDocument/publishDiagnostics",
      params: {
        uri: uri,
        diagnostics: diagnostics
      }
    )

    send_response(response)
  end

  def send_response(response)
    content = response.to_json
    $stdout.write("Content-Length: #{content.bytesize}\r\n\r\n#{content}")
    $stdout.flush
  end

  def log_info(message)
    warn("[haml-lsp] INFO: #{message}")
  end

  def log_error(message)
    warn("[haml-lsp] ERROR: #{message}")
  end

  def show_error_message(message)
    response = lsp_response_json(
      id: nil,
      method: "window/showMessage",
      params: {
        type: 1, # Error
        message: message
      }
    )

    send_response(response)
  end

  def lsp_response_json(id:, method: nil, result: nil, params: nil, error: nil)
    response = { "jsonrpc" => "2.0", "id" => id }
    response["method"] = method if method
    response["params"] = params if params
    response["result"] = result if result
    response["error"] = error if error
    response
  end

  def lsp_capabilities
    {
      textDocumentSync: {
        openClose: true,
        change: 1, # Full document sync
        save: { includeText: false }
      }
    }
  end
end
