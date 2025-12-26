# frozen_string_literal: true

module HamlLsp
  Interface = LanguageServer::Protocol::Interface
  Constant = LanguageServer::Protocol::Constant

  # A notification to be sent to the client
  class Message
    attr_reader :method, :params

    def initialize(method:, params:)
      @method = method
      @params = params
    end

    # @abstract
    def to_hash
      raise AbstractMethodInvokedError
    end
  end

  # A request to be sent to the client
  class Request < Message
    attr_reader :id

    def initialize(data = {})
      @id = data[:id]
      super(method: data[:method], params: data[:params])
    end

    def root_uri
      decode_uri(params[:rootUri]) if params
    end

    def document_uri
      params[:textDocument][:uri] if params && params[:textDocument]
    end

    def document_uri_path
      decode_uri(document_uri)
    end

    def document_content
      case method
      when "textDocument/didOpen", "textDocument/formatting"
        params[:textDocument][:text]
      when "textDocument/didChange"
        # For full document sync, the last change contains the full text
        changes = params[:contentChanges]
        changes.last[:text] if changes && !changes.empty?
      end
    end

    # @override
    def to_hash
      hash = { id: @id, method: @method }

      hash[:params] = @params.to_hash if @params

      hash
    end

    private

    def decode_uri(uri)
      URI.decode_uri_component(uri.sub("file://", ""))
    end
  end

  # Reads JSON RPC messages from the given IO in a loop
  class MessageReader
    def initialize(io)
      @io = io
    end

    def each_message(&block)
      while (headers = @io.gets("\r\n\r\n"))
        raw_message = @io.read(headers[/Content-Length: (\d+)/i, 1].to_i)
        message = Request.new(JSON.parse(raw_message, symbolize_names: true))
        block.call(message)
      end
    end
  end

  # Writes JSON RPC messages to the given IO
  class MessageWriter
    def initialize(io)
      @io = io
    end

    def write(message)
      json_message = message.to_json

      @io.write("Content-Length: #{json_message.bytesize}\r\n\r\n#{json_message}")
      @io.flush
    end
  end
end
