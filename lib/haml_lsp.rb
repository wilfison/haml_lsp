# frozen_string_literal: true

require "haml_lint"

require_relative "haml_lsp/version"
require_relative "haml_lsp/server_responder"
require_relative "haml_lsp/server"
require_relative "haml_lsp/linter"
require_relative "haml_lsp/linter/runner"

module HamlLsp # rubocop:disable Style/ClassAndModuleChildren
  class Error < StandardError; end
end
