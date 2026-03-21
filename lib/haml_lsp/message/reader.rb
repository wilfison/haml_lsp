# frozen_string_literal: true

module HamlLsp
  module Message
    # Reads JSON RPC messages from the given IO in a loop
    class Reader
      def initialize(io)
        @io = io
      end

      def each_message(&block)
        while (headers = @io.gets("\r\n\r\n"))
          length = headers[/Content-Length: (\d+)/i, 1]&.to_i
          next unless length&.positive?

          raw_message = @io.read(length)
          message = Message::Request.new(JSON.parse(raw_message, symbolize_names: true))
          block.call(message)
        end
      end
    end
  end
end
