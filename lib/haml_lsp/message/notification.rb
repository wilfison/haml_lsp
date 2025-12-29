# frozen_string_literal: true

module HamlLsp
  module Message
    # A notification to be sent to the client
    class Notification < Base
      class << self
        def window_show_message(message, type: HamlLsp::Constant::MessageType::INFO)
          new(
            method: "window/showMessage",
            params: HamlLsp::Interface::ShowMessageParams.new(type: type, message: message)
          )
        end

        def window_log_message(message, type: HamlLsp::Constant::MessageType::LOG)
          new(
            method: "window/logMessage",
            params: HamlLsp::Interface::LogMessageParams.new(
              type: type,
              message: "[Haml LSP] #{message}"
            )
          )
        end

        def telemetry(data)
          new(
            method: "telemetry/event",
            params: data
          )
        end

        def progress_begin(id, title, percentage: nil, message: nil)
          new(
            method: "$/progress",
            params: HamlLsp::Interface::ProgressParams.new(
              token: id,
              value: HamlLsp::Interface::WorkDoneProgressBegin.new(
                kind: "begin",
                title: title,
                percentage: percentage,
                message: message
              )
            )
          )
        end

        def progress_report(id, percentage: nil, message: nil)
          new(
            method: "$/progress",
            params: HamlLsp::Interface::ProgressParams.new(
              token: id,
              value: HamlLsp::Interface::WorkDoneProgressReport.new(
                kind: "report",
                percentage: percentage,
                message: message
              )
            )
          )
        end

        def progress_end(id)
          Notification.new(
            method: "$/progress",
            params: HamlLsp::Interface::ProgressParams.new(
              token: id,
              value: HamlLsp::Interface::WorkDoneProgressEnd.new(kind: "end")
            )
          )
        end

        def publish_diagnostics(uri, diagnostics, version: nil)
          new(
            method: "textDocument/publishDiagnostics",
            params: HamlLsp::Interface::PublishDiagnosticsParams.new(
              uri: uri,
              diagnostics: diagnostics,
              version: version
            )
          )
        end
      end

      def to_hash
        hash = { method: @method }
        hash[:params] = @params.to_hash if @params

        hash
      end
    end
  end
end
