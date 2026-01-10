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
    end
  end
end
