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
  end
end
