# frozen_string_literal: true

require "test_helper"

class HamlTagsProviderTest < Minitest::Test
  def test_completion_items_returns_array
    items = HamlLsp::Haml::TagsProvider.completion_items

    assert_instance_of Array, items
    refute_empty items
  end

  def test_includes_common_html_tags
    items = HamlLsp::Haml::TagsProvider.completion_items
    labels = items.map { |item| item[:label] }

    assert_includes labels, "div"
    assert_includes labels, "span"
    assert_includes labels, "p"
    assert_includes labels, "a"
    assert_includes labels, "img"
  end

  def test_includes_haml_tags_with_percent
    items = HamlLsp::Haml::TagsProvider.completion_items
    labels = items.map { |item| item[:label] }

    assert_includes labels, "%div"
    assert_includes labels, "%span"
    assert_includes labels, "%p"
  end

  def test_html_tags_have_correct_structure
    items = HamlLsp::Haml::TagsProvider.completion_items
    html_tag = items.find { |item| item[:label] == "div" }

    assert_equal "div", html_tag[:label]
    assert_equal 14, html_tag[:kind] # Keyword kind
    assert_equal "HTML tag", html_tag[:detail]
  end

  def test_haml_tags_have_correct_structure
    items = HamlLsp::Haml::TagsProvider.completion_items
    haml_tag = items.find { |item| item[:label] == "%div" }

    assert_equal "%div", haml_tag[:label]
    assert_equal 15, haml_tag[:kind] # Snippet kind
    assert_equal "HAML tag", haml_tag[:detail]
  end
end
