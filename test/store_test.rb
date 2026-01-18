# frozen_string_literal: true

require "test_helper"

module HamlLsp
  class StoreTest < Minitest::Test
    def setup
      @store = HamlLsp::Store.new
      @uri = "file:///test.haml"
      @content = "%h1 Hello World"
    end

    def test_initialization
      assert_instance_of HamlLsp::Store, @store
      assert_equal HamlLsp::Store::DEFAULT_MAX_DOCUMENTS, @store.max_documents
      assert_equal HamlLsp::Store::DEFAULT_TTL, @store.ttl_seconds
    end

    def test_initialization_with_custom_limits
      store = HamlLsp::Store.new(max_documents: 50, ttl_seconds: 1800)

      assert_equal 50, store.max_documents
      assert_equal 1800, store.ttl_seconds
    end

    def test_set_creates_new_document
      document = @store.set(@uri, @content)

      assert_instance_of HamlLsp::Document, document
      assert_equal @uri, document.uri
      assert_equal @content, document.content
    end

    def test_get_returns_document
      @store.set(@uri, @content)
      document = @store.get(@uri)

      assert_instance_of HamlLsp::Document, document
      assert_equal @uri, document.uri
    end

    def test_get_returns_nil_for_nonexistent_document
      document = @store.get("file:///nonexistent.haml")

      assert_nil document
    end

    def test_set_updates_existing_document
      @store.set(@uri, @content)
      new_content = "%h2 Updated"
      document = @store.set(@uri, new_content)

      assert_equal new_content, document.content
      assert_equal @uri, document.uri
    end

    def test_delete_removes_document
      @store.set(@uri, @content)
      @store.delete(@uri)
      document = @store.get(@uri)

      assert_nil document
    end

    def test_clear_removes_all_documents
      @store.set("file:///test1.haml", "content1")
      @store.set("file:///test2.haml", "content2")
      @store.clear

      assert_nil @store.get("file:///test1.haml")
      assert_nil @store.get("file:///test2.haml")
    end

    def test_each_iterates_over_documents
      @store.set("file:///test1.haml", "content1")
      @store.set("file:///test2.haml", "content2")

      documents = @store.documents.values.to_a

      assert_equal 2, documents.length
      assert(documents.all? { |d| d.is_a?(HamlLsp::Document) })
    end

    def test_set_returns_same_document_object_on_update
      doc1 = @store.set(@uri, @content)
      doc2 = @store.set(@uri, "%h2 Updated")

      assert_same doc1, doc2
    end

    def test_size_returns_document_count
      assert_equal 0, @store.size

      @store.set("file:///test1.haml", "content1")

      assert_equal 1, @store.size

      @store.set("file:///test2.haml", "content2")

      assert_equal 2, @store.size

      @store.delete("file:///test1.haml")

      assert_equal 1, @store.size
    end

    def test_cleanup_stale_documents
      store = HamlLsp::Store.new(ttl_seconds: 1)

      store.set("file:///test1.haml", "content1")
      store.set("file:///test2.haml", "content2")

      assert_equal 2, store.size

      # Wait for TTL to expire
      sleep(1.1)

      # Add a new document to trigger access time update
      store.set("file:///test3.haml", "content3")

      # Cleanup stale documents
      removed = store.cleanup_stale_documents

      assert_equal 2, removed
      assert_equal 1, store.size
      assert_nil store.get("file:///test1.haml")
      assert_nil store.get("file:///test2.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test3.haml")
    end

    def test_max_documents_limit_removes_lru
      store = HamlLsp::Store.new(max_documents: 3, ttl_seconds: 3600)

      store.set("file:///test1.haml", "content1")
      sleep(0.01)
      store.set("file:///test2.haml", "content2")
      sleep(0.01)
      store.set("file:///test3.haml", "content3")

      assert_equal 3, store.size

      # Adding 4th document should remove oldest (test1)
      store.set("file:///test4.haml", "content4")

      assert_equal 3, store.size
      assert_nil store.get("file:///test1.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test2.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test3.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test4.haml")
    end

    def test_max_documents_limit_prioritizes_stale_removal
      store = HamlLsp::Store.new(max_documents: 3, ttl_seconds: 1)

      store.set("file:///test1.haml", "content1")
      store.set("file:///test2.haml", "content2")

      # Wait for TTL
      sleep(1.1)

      # This should still work and not remove test2
      store.set("file:///test3.haml", "content3")

      # Adding 4th should remove stale ones first (test1 and test2)
      store.set("file:///test4.haml", "content4")

      assert_operator store.size, :<=, 3
      assert_nil store.get("file:///test1.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test3.haml")
      assert_instance_of HamlLsp::Document, store.get("file:///test4.haml")
    end

    def test_get_updates_access_time
      store = HamlLsp::Store.new(ttl_seconds: 1)

      store.set("file:///test1.haml", "content1")
      sleep(0.5)

      # Access should update time
      store.get("file:///test1.haml")
      sleep(0.6)

      # Should not be removed as it was accessed 0.6s ago
      removed = store.cleanup_stale_documents

      assert_equal 0, removed
      assert_instance_of HamlLsp::Document, store.get("file:///test1.haml")
    end

    def test_delete_removes_access_time
      @store.set(@uri, @content)
      @store.delete(@uri)

      # Verify cleanup doesn't throw errors on deleted documents
      assert_equal 0, @store.cleanup_stale_documents
    end
  end
end
