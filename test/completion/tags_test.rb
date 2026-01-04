# frozen_string_literal: true

require "test_helper"

module Completion
  class TagsTest < Minitest::Test
    def test_completion_items_returns_array
      items = HamlLsp::Completion::Tags.completion_items("%")

      assert_instance_of Array, items
      refute_empty items
    end

    def test_includes_common_html_tags
      items = HamlLsp::Completion::Tags.completion_items("%")
      labels = items.map { |item| item[:label] }

      assert_includes labels, "div"
      assert_includes labels, "span"
      assert_includes labels, "p"
      assert_includes labels, "a"
      assert_includes labels, "img"
    end

    def test_html_tags_have_correct_structure
      items = HamlLsp::Completion::Tags.completion_items("%")
      html_tag = items.find { |item| item[:label] == "div" }

      assert_equal "div", html_tag[:label]
      assert_equal 14, html_tag[:kind] # Keyword kind
      assert_equal "HTML <div> element", html_tag[:detail]
    end
  end
end
