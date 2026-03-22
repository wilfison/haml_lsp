# frozen_string_literal: true

require "test_helper"
require "json"

# Integration tests that send real JSON-RPC messages through the full
# Reader -> Server -> Writer pipeline using IO pipes.
class IntegrationTest < Minitest::Test
  def setup
    # client writes -> server reads
    @server_read, @client_write = IO.pipe
    # server writes -> client reads
    @client_read, @server_write = IO.pipe

    @server = HamlLsp::Server::Base.new(
      input: @server_read,
      output: @server_write
    )

    @server_thread = Thread.new do
      Thread.current.report_on_exception = false
      @server.start
    end
  end

  def teardown
    @client_write.close unless @client_write.closed?
    @server_read.close unless @server_read.closed?
    @server_write.close unless @server_write.closed?
    @client_read.close unless @client_read.closed?
    @server_thread.kill
  end

  def test_initialize_handshake
    send_request(id: 1, method: "initialize", params: { capabilities: {} })

    response = read_response_with_id(1)

    assert_equal "2.0", response[:jsonrpc]
    assert_equal 1, response[:id]
    assert response[:result][:capabilities]
    assert_equal "haml_lsp", response[:result][:serverInfo][:name]
  end

  def test_shutdown_returns_null_result
    send_request(id: 1, method: "initialize", params: { capabilities: {} })
    read_response_with_id(1)

    send_request(id: 2, method: "shutdown", params: {})

    response = read_response_with_id(2)

    assert_equal 2, response[:id]
    assert_nil response[:result]
  end

  def test_did_open_and_formatting
    send_request(id: 1, method: "initialize", params: { capabilities: {} })
    read_response_with_id(1)

    send_notification(
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: "file:///test.haml",
          languageId: "haml",
          version: 1,
          text: "%h1   Hello World  \n"
        }
      }
    )

    sleep(0.05)

    send_request(
      id: 3,
      method: "textDocument/formatting",
      params: {
        textDocument: { uri: "file:///test.haml" },
        options: { tabSize: 2, insertSpaces: true }
      }
    )

    response = read_response_with_id(3)

    assert_equal 3, response[:id]
    assert_instance_of Array, response[:result]
    refute_empty response[:result]

    new_text = response[:result].first[:newText]

    refute_match(/  $/, new_text)
  end

  def test_completion_returns_result
    send_request(id: 1, method: "initialize", params: { capabilities: {} })
    read_response_with_id(1)

    send_notification(
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: "file:///test.haml",
          languageId: "haml",
          version: 1,
          text: "%d\n"
        }
      }
    )

    sleep(0.05)

    send_request(
      id: 4,
      method: "textDocument/completion",
      params: {
        textDocument: { uri: "file:///test.haml" },
        position: { line: 0, character: 2 }
      }
    )

    response = read_response_with_id(4)

    assert_equal 4, response[:id]
    assert_instance_of Array, response[:result]
  end

  def test_definition_returns_result
    send_request(id: 1, method: "initialize", params: { capabilities: {} })
    read_response_with_id(1)

    send_notification(
      method: "textDocument/didOpen",
      params: {
        textDocument: {
          uri: "file:///test.haml",
          languageId: "haml",
          version: 1,
          text: "%h1 Hello\n"
        }
      }
    )

    sleep(0.05)

    send_request(
      id: 5,
      method: "textDocument/definition",
      params: {
        textDocument: { uri: "file:///test.haml" },
        position: { line: 0, character: 5 }
      }
    )

    response = read_response_with_id(5)

    assert_equal 5, response[:id]
    assert_nil response[:result]
  end

  def test_unknown_method_does_not_crash_server
    send_request(id: 1, method: "initialize", params: { capabilities: {} })
    read_response_with_id(1)

    send_notification(method: "unknown/method", params: {})

    send_request(id: 2, method: "shutdown", params: {})

    response = read_response_with_id(2)

    assert_equal 2, response[:id]
  end

  private

  def send_request(id:, method:, params:)
    write_message({ jsonrpc: "2.0", id: id, method: method, params: params })
  end

  def send_notification(method:, params:)
    write_message({ jsonrpc: "2.0", method: method, params: params })
  end

  def write_message(message)
    json = message.to_json
    @client_write.write("Content-Length: #{json.bytesize}\r\n\r\n#{json}")
    @client_write.flush
  end

  def read_response_with_id(expected_id, timeout: 5)
    deadline = Time.now + timeout

    loop do
      remaining = deadline - Time.now
      raise "Timeout waiting for response id=#{expected_id}" if remaining <= 0

      raise "Timeout waiting for response id=#{expected_id}" unless @client_read.wait_readable(remaining)

      headers = @client_read.gets("\r\n\r\n")
      raise "Server closed connection" unless headers

      length = headers[/Content-Length: (\d+)/i, 1]&.to_i
      next unless length&.positive?

      raw = @client_read.read(length)
      parsed = JSON.parse(raw, symbolize_names: true)

      return parsed if parsed[:id] == expected_id
    end
  end
end
