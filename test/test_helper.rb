# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "irb"
require "stringio"
require "haml_lsp"

require "minitest/autorun"
require "minitest/mock"

ENV["HAML_LSP_LOG_LEVEL"] = "fatal"

FIXTURES_PATH = File.expand_path("fixtures", __dir__)

# Silence LSP log output during tests so JSON-RPC messages don't pollute the test runner stdout.
NULL_IO = StringIO.new
HamlLsp.writer = HamlLsp::Message::Writer.new(NULL_IO)

class MockRequest
  attr_reader :method, :document_uri, :document_content, :document_uri_path, :params, :id

  def initialize(method:, **kwargs)
    @method = method
    @document_uri = kwargs[:document_uri]
    @document_content = kwargs[:document_content]
    @document_uri_path = kwargs[:document_uri_path]
    @params = kwargs[:params]
    @id = kwargs[:id] || 1
  end
end
