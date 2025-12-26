# frozen_string_literal: true

module HamlLsp
  Interface = LanguageServer::Protocol::Interface
  Constant = LanguageServer::Protocol::Constant

  # Reads JSON RPC messages from the given IO in a loop
  class MessageReader
    def initialize(io)
      @io = io
    end

    def each_message(&block)
      while (headers = @io.gets("\r\n\r\n"))
        raw_message = @io.read(headers[/Content-Length: (\d+)/i, 1].to_i)
        block.call(JSON.parse(raw_message, symbolize_names: true))
      end
    end
  end

  # Writes JSON RPC messages to the given IO
  class MessageWriter
    def initialize(io)
      @io = io
    end

    def write(message)
      message[:jsonrpc] = "2.0"
      json_message = message.to_json

      @io.write("Content-Length: #{json_message.bytesize}\r\n\r\n#{json_message}")
      @io.flush
    end
  end
end
