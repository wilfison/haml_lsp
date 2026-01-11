# frozen_string_literal: true

module HamlLsp
  module Message
    # A request to be sent to the client
    class Request < Base
      attr_reader :id

      def initialize(data = {})
        @id = data[:id]
        super(method: data[:method], params: data[:params] || {})
      end

      def root_uri
        decode_uri(params[:rootUri]) if params
      end

      def document_uri
        return params[:textDocument][:uri] if params && params[:textDocument]
        return params[:data][:uri] if params && params[:data] && params[:data][:uri]

        params[:uri]
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
  end
end
