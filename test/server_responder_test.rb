# frozen_string_literal: true

require "test_helper"

class HamlLsp::ServerResponderTest < Minitest::Test
  class TestServer
    include HamlLsp::ServerResponder
  end

  def setup
    @server = TestServer.new
  end

  def test_lsp_response_json_with_result
    response = @server.lsp_response_json(id: 1, result: { success: true })

    assert_equal "2.0", response["jsonrpc"]
    assert_equal 1, response["id"]
    assert_equal({ success: true }, response["result"])
  end

  def test_lsp_response_json_with_method_and_params
    response = @server.lsp_response_json(
      id: 2,
      method: "testMethod",
      params: { key: "value" }
    )

    assert_equal "2.0", response["jsonrpc"]
    assert_equal 2, response["id"]
    assert_equal "testMethod", response["method"]
    assert_equal({ key: "value" }, response["params"])
  end

  def test_lsp_response_json_with_error
    response = @server.lsp_response_json(
      id: 3,
      error: { code: -32_600, message: "Invalid Request" }
    )

    assert_equal "2.0", response["jsonrpc"]
    assert_equal 3, response["id"]
    assert_equal({ code: -32_600, message: "Invalid Request" }, response["error"])
  end

  def test_lsp_capabilities
    capabilities = @server.lsp_capabilities

    assert_instance_of Hash, capabilities
    assert capabilities[:textDocumentSync]
    assert_equal true, capabilities[:textDocumentSync][:openClose]
    assert_equal 1, capabilities[:textDocumentSync][:change]
  end
end
