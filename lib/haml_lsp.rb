# frozen_string_literal: true

require "haml_lint"
require "language_server/protocol"

require_relative "haml_lsp/version"
require_relative "haml_lsp/utils"
require_relative "haml_lsp/server_responder"
require_relative "haml_lsp/server"
require_relative "haml_lsp/linter"
require_relative "haml_lsp/lint/runner"
require_relative "haml_lsp/rails/detector"

module HamlLsp
  class Error < StandardError; end
end
