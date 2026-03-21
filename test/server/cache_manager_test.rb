# frozen_string_literal: true

require "test_helper"

class CacheManagerTest < Minitest::Test
  def test_rails_project_detection
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: nil)

    refute_predicate cache_manager, :rails_project?
  end

  def test_rails_routes_returns_empty_hash_by_default
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: nil)

    assert_empty(cache_manager.rails_routes)
  end

  def test_invalidate_rails_routes
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: nil)
    cache_manager.invalidate_rails_routes

    assert_empty(cache_manager.rails_routes)
  end

  def test_initialization_with_root_uri
    root_uri = "/tmp/test"
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: root_uri, use_bundle: true)

    refute_predicate cache_manager, :rails_project?
  end

  def test_load_rails_routes_async_loads_in_background
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: "/tmp/test")

    # Stub rails_project? to true and extraction to return test data
    cache_manager.instance_variable_set(:@rails_project, true)
    routes = { "users" => { prefix: "users", verbs: ["GET"] } }

    HamlLsp::Rails::RoutesExtractor.stub(:extract_routes, routes) do
      cache_manager.load_rails_routes_async

      # rails_routes should wait for the thread and return results
      result = cache_manager.rails_routes

      assert_equal routes, result
    end
  end

  def test_rails_routes_waits_for_async_load
    cache_manager = HamlLsp::Server::CacheManager.new(root_uri: "/tmp/test")
    cache_manager.instance_variable_set(:@rails_project, true)

    routes = { "posts" => { prefix: "posts", verbs: ["POST"] } }

    # Simulate slow extraction
    slow_extract = lambda { |_path|
      sleep(0.1)
      routes
    }

    HamlLsp::Rails::RoutesExtractor.stub(:extract_routes, slow_extract) do
      cache_manager.load_rails_routes_async

      result = cache_manager.rails_routes

      assert_equal routes, result
    end
  end
end
