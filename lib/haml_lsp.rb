# frozen_string_literal: true

require "haml_lint"
require "language_server/protocol"

require_relative "haml_lsp/version"
require_relative "haml_lsp/utils"

require_relative "haml_lsp/message/base"
require_relative "haml_lsp/message/notification"
require_relative "haml_lsp/message/request"
require_relative "haml_lsp/message/reader"
require_relative "haml_lsp/message/writer"
require_relative "haml_lsp/message/result"

require_relative "haml_lsp/server_responder"
require_relative "haml_lsp/server"
require_relative "haml_lsp/linter"
require_relative "haml_lsp/lint/runner"
require_relative "haml_lsp/autocorrector"
require_relative "haml_lsp/store"
require_relative "haml_lsp/document"
require_relative "haml_lsp/rails/detector"
require_relative "haml_lsp/rails/routes_extractor"

require_relative "haml_lsp/completion/tags"
require_relative "haml_lsp/completion/attributes"
require_relative "haml_lsp/completion/routes"
require_relative "haml_lsp/completion/provider"

# The main module for HamlLSP
module HamlLsp
  class Error < StandardError; end

  def self.reader
    @reader ||= HamlLsp::Message::Reader.new($stdin)
  end

  def self.writer
    @writer ||= HamlLsp::Message::Writer.new($stdout)
  end

  def self.log(message, type: HamlLsp::Constant::MessageType::LOG)
    writer.write(HamlLsp::Message::Notification.window_log_message(message, type: type).to_hash)
  end

  def self.log_error(message)
    log(message, type: HamlLsp::Constant::MessageType::ERROR)
  end
end
