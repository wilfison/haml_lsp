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
end
