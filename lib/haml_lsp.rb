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
require_relative "haml_lsp/rails/routes_extractor"
require_relative "haml_lsp/haml/tags_provider"
require_relative "haml_lsp/haml/attributes_provider"

module HamlLsp
  class Error < StandardError; end
end
