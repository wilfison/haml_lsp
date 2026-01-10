# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "irb"
require "haml_lsp"

require "minitest/autorun"

ENV["HAML_LSP_LOG_LEVEL"] = "fatal"

FIXTURES_PATH = File.expand_path("fixtures", __dir__)

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
