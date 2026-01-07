# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "irb"
require "haml_lsp"

require "minitest/autorun"

ENV["HAML_LSP_LOG_LEVEL"] = "fatal"

FIXTURES_PATH = File.expand_path("fixtures", __dir__)
