# frozen_string_literal: true

# LSP-related utilities and helpers
module HamlLsp::ServerResponder
  def lsp_respond_to_initialize(id)
    capabilities = HamlLsp::Interface::ServerCapabilities.new(
      text_document_sync: HamlLsp::Interface::TextDocumentSyncOptions.new(
        open_close: true,
        change: HamlLsp::Constant::TextDocumentSyncKind::FULL,
        save: HamlLsp::Interface::SaveOptions.new(include_text: false)
      )
    )

    result = HamlLsp::Interface::InitializeResult.new(
      capabilities: capabilities,
      server_info: {
        name: "haml_lsp",
        version: HamlLsp::VERSION
      }
    )

    message = HamlLsp::Interface::ResponseMessage.new(
      jsonrpc: "2.0",
      id: id,
      result: result
    )

    send_message(message)
  end

  def lasp_respond_to_shutdown(request)
    HamlLsp::Interface::ResponseMessage.new(
      jsonrpc: "2.0",
      id: request[:id],
      result: nil
    )
  end

  def lsp_respond_to_diagnostics(uri, diagnostics)
    params = HamlLsp::Interface::PublishDiagnosticsParams.new(
      uri: uri,
      diagnostics: diagnostics
    )

    notification = HamlLsp::Interface::NotificationMessage.new(
      jsonrpc: "2.0",
      method: "textDocument/publishDiagnostics",
      params: params
    )

    send_message(notification)
  end

  def send_message(message)
    @writer.write(message)
  end

  def log_info(message)
    return if ENV["HAML_LSP_LOG_LEVEL"] == "fatal"

    warn("[haml-lsp] INFO: #{message}")
  end

  def log_error(message)
    warn("[haml-lsp] ERROR: #{message}")
  end

  def show_error_message(message)
    params = HamlLsp::Interface::ShowMessageParams.new(
      type: HamlLsp::Constant::MessageType::ERROR,
      message: message
    )

    notification = HamlLsp::Interface::NotificationMessage.new(
      jsonrpc: "2.0",
      method: "window/showMessage",
      params: params
    )

    send_message(notification)
  end
end
