# frozen_string_literal: true

require "test_helper"

class HamlAttributesProviderTest < Minitest::Test
  def test_completion_items_returns_array
    items = HamlLsp::Haml::AttributesProvider.completion_items

    assert_instance_of Array, items
    refute_empty items
  end

  def test_includes_global_attributes
    items = HamlLsp::Haml::AttributesProvider.completion_items
    labels = items.map { |item| item[:label] }

    assert_includes labels, "id"
    assert_includes labels, "class"
    assert_includes labels, "style"
    assert_includes labels, "title"
  end

  def test_includes_haml_specific_syntax
    items = HamlLsp::Haml::AttributesProvider.completion_items
    labels = items.map { |item| item[:label] }

    assert_includes labels, "{"
    assert_includes labels, "("
    assert_includes labels, "."
    assert_includes labels, "#"
  end

  def test_global_attributes_have_correct_structure
    items = HamlLsp::Haml::AttributesProvider.completion_items
    id_attr = items.find { |item| item[:label] == "id" }

    assert_equal "id", id_attr[:label]
    assert_equal 10, id_attr[:kind] # Property kind
    assert_equal "HTML attribute", id_attr[:detail]
  end

  def test_haml_syntax_has_correct_structure
    items = HamlLsp::Haml::AttributesProvider.completion_items
    hash_syntax = items.find { |item| item[:label] == "{" }

    assert_equal "{", hash_syntax[:label]
    assert_equal 15, hash_syntax[:kind] # Snippet kind
    assert_equal "Ruby hash attributes", hash_syntax[:detail]
  end

  def test_tag_specific_attributes
    items = HamlLsp::Haml::AttributesProvider.completion_items(tag: "a")
    labels = items.map { |item| item[:label] }

    assert_includes labels, "href"
    assert_includes labels, "target"
  end

  def test_tag_specific_img_attributes
    items = HamlLsp::Haml::AttributesProvider.completion_items(tag: "img")
    labels = items.map { |item| item[:label] }

    assert_includes labels, "src"
    assert_includes labels, "alt"
  end
end
