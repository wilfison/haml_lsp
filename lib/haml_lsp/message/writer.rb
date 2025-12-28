# frozen_string_literal: true

module HamlLsp
  module Message
    # Writes JSON RPC messages to the given IO
    class Writer
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
end
