# frozen_string_literal: true

require "test_helper"

module Completion
  class AttributesTest < Minitest::Test
    def test_completion_items_returns_array
      items = HamlLsp::Completion::Attributes.completion_items("%div{")

      assert_instance_of Array, items
      refute_empty items
    end

    def test_includes_global_attributes
      items = HamlLsp::Completion::Attributes.completion_items("%div{")
      labels = items.map { |item| item[:label] }

      assert_includes labels, "id"
      assert_includes labels, "class"
      assert_includes labels, "style"
      assert_includes labels, "title"
    end

    def test_global_attributes_have_correct_structure
      items = HamlLsp::Completion::Attributes.completion_items("%div{")
      id_attr = items.find { |item| item[:label] == "id" }

      assert_equal "id", id_attr[:label]
      assert_equal 10, id_attr[:kind] # Property kind
      assert_equal "HTML attribute", id_attr[:detail]
    end

    def test_tag_specific_attributes
      items = HamlLsp::Completion::Attributes.completion_items("%a.link{")
      labels = items.map { |item| item[:label] }

      assert_includes labels, "href"
      assert_includes labels, "target"
    end

    def test_tag_specific_img_attributes
      items = HamlLsp::Completion::Attributes.completion_items("%img#brand{")
      labels = items.map { |item| item[:label] }

      assert_includes labels, "src"
      assert_includes labels, "alt"
    end

    def test_completion_data_attribute_with_hyphen
      items = HamlLsp::Completion::Attributes.global_attribute_completions(":")
      data_attr = items.find { |item| item[:label] == "data-" }

      assert_equal "data-", data_attr[:label]
      assert_equal 10, data_attr[:kind] # Property kind
      assert_equal "HTML attribute", data_attr[:detail]
      assert_equal "Global HTML attribute: data-", data_attr[:documentation]
      assert_equal "\"data-$1\":$0", data_attr[:insert_text]
      assert_equal 2, data_attr[:insert_text_format] # Snippet format
    end
  end
end
