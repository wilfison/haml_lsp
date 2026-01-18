# frozen_string_literal: true

module HamlLsp
  module Server
    # Server class to handle LSP requests and coordinate request processing
    class Base
      include HamlLsp::Server::Responder

      attr_reader :root_uri, :use_bundle, :enable_lint

      def initialize(use_bundle: false, enable_lint: false, root_uri: nil)
        @root_uri = URI.decode_uri_component(root_uri.sub("file://", "")) if root_uri
        @use_bundle = use_bundle
        @enable_lint = enable_lint
        @initialized = false

        @state_manager = HamlLsp::Server::StateManager.new
        @cache_manager = HamlLsp::Server::CacheManager.new(root_uri: @root_uri, use_bundle: @use_bundle)
        @request_handler = HamlLsp::Server::RequestHandler.new(
          store: store,
          cache_manager: @cache_manager,
          enable_lint: @enable_lint,
          root_uri: @root_uri,
          server: self
        )
      end

      def start
        HamlLsp.log("Starting HAML LSP")
        HamlLsp.log("    Use bundle: #{@use_bundle}")
        HamlLsp.log("    Enable lint: #{@enable_lint}")
        HamlLsp.log("    Root URI: #{@root_uri || "not set"}")

        HamlLsp.reader.each_message do |message|
          response_message = @request_handler.handle(message)
          next unless response_message

          send_message(response_message)
        rescue StandardError => e
          HamlLsp.log_error("Fatal error (##{message.id}:#{message.method}): #{e.message}")
          HamlLsp.log_error(e.backtrace.join("\n"))
          exit(1)
        end
      end

      private

      def store
        @store ||= HamlLsp::Store.new
      end
    end
  end
end
