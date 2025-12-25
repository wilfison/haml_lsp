# frozen_string_literal: true

require "test_helper"

class HamlLsp::ServerTest < Minitest::Test
  def setup
    @server = HamlLsp::Server.new(
      use_bundle: false,
      enable_lint: false,
      root_uri: nil
    )
  end

  def test_server_initialization
    refute_nil @server
    assert_instance_of HamlLsp::Server, @server
  end

  def test_server_has_use_bundle_attribute
    assert_respond_to @server, :use_bundle
    assert_equal false, @server.use_bundle
  end

  def test_server_has_enable_lint_attribute
    assert_respond_to @server, :enable_lint
    assert_equal false, @server.enable_lint
  end

  def test_server_has_root_uri_attribute
    assert_respond_to @server, :root_uri
    assert_nil @server.root_uri
  end

  def test_server_with_root_uri
    server = HamlLsp::Server.new(
      root_uri: "file:///home/user/project"
    )

    assert_equal "/home/user/project", server.root_uri
  end

  def test_server_with_use_bundle
    server = HamlLsp::Server.new(use_bundle: true)

    assert_equal true, server.use_bundle
  end

  def test_server_with_enable_lint
    server = HamlLsp::Server.new(enable_lint: true)

    assert_equal true, server.enable_lint
  end
end
