# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Server
    class BaseTest < Minitest::Test
      def setup
        @server = HamlLsp::Server::Base.new(
          use_bundle: false,
          enable_lint: false,
          root_uri: nil
        )
      end

      def test_server_initialization
        refute_nil @server
        assert_instance_of HamlLsp::Server::Base, @server
      end

      def test_server_has_use_bundle_attribute
        assert_respond_to @server, :use_bundle
        refute @server.use_bundle
      end

      def test_server_has_enable_lint_attribute
        assert_respond_to @server, :enable_lint
        refute @server.enable_lint
      end

      def test_server_has_root_uri_attribute
        assert_respond_to @server, :root_uri
        assert_nil @server.root_uri
      end

      def test_server_with_root_uri
        server = HamlLsp::Server::Base.new(
          root_uri: "file:///home/user/project"
        )

        assert_equal "/home/user/project", server.root_uri
      end

      def test_server_with_use_bundle
        server = HamlLsp::Server::Base.new(use_bundle: true)

        assert server.use_bundle
      end

      def test_server_with_enable_lint
        server = HamlLsp::Server::Base.new(enable_lint: true)

        assert server.enable_lint
      end

      def test_start_writes_response_for_requests
        message = HamlLsp::Message::Request.new(id: 1, method: "initialize", params: { capabilities: {} })
        written_messages = []

        mock_reader = Minitest::Mock.new
        mock_reader.expect(:each_message, nil) do |&block|
          block.call(message)
        end

        mock_writer = Object.new
        mock_writer.singleton_class.define_method(:write) { |msg| written_messages << msg }

        @server.instance_variable_set(:@reader, mock_reader)
        @server.instance_variable_set(:@writer, mock_writer)
        HamlLsp.writer = mock_writer
        @server.start

        # Should have log messages + the initialize response
        response = written_messages.find { |m| m[:id] == 1 }

        refute_nil response, "Expected an initialize response with id=1"
        assert response[:result]
      ensure
        HamlLsp.writer = HamlLsp::Message::Writer.new($stdout)
      end

      def test_start_continues_after_request_handler_error
        message1 = HamlLsp::Message::Request.new(id: 1, method: "textDocument/completion", params: {})
        message2 = HamlLsp::Message::Request.new(id: 2, method: "shutdown", params: {})

        messages_yielded = []
        mock_reader = Minitest::Mock.new
        mock_reader.expect(:each_message, nil) do |&block|
          [message1, message2].each do |msg|
            messages_yielded << msg
            block.call(msg)
          end
        end

        # Make request_handler raise on first message
        call_count = 0
        mock_handler = Minitest::Mock.new
        mock_handler.expect(:handle, nil) do |_req|
          call_count += 1
          raise StandardError, "test error" if call_count == 1

          HamlLsp::Message::Result.new(id: 2, response: nil)
        end
        mock_handler.expect(:handle, HamlLsp::Message::Result.new(id: 2, response: nil)) do |_req|
          true
        end

        @server.instance_variable_set(:@reader, mock_reader)
        @server.instance_variable_set(:@request_handler, mock_handler)
        @server.start

        assert_equal 2, messages_yielded.size, "Server should continue processing after an error"
      end
    end
  end
end
