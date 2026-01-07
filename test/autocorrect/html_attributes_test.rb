# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class HtmlAttributesTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::HtmlAttributes
    end

    def test_autocorrect_with_html_attributes
      line = '  %div(class="container" id="main")'
      expected = "  %div{class: 'container', id: 'main'}"

      assert_equal expected, @autocorrector.autocorrect(line)
    end

    def test_autocorrect_with_no_attributes
      line = "  %div"
      expected = "  %div"

      assert_equal expected, @autocorrector.autocorrect(line)
    end

    def test_autocorrect_with_mixed_quotes
      line = "  %div(class='container' id=\"main\" data-value=123)"
      expected = "  %div{class: 'container', id: 'main', 'data-value': 123}"

      assert_equal expected, @autocorrector.autocorrect(line)
    end

    def test_autocorrect_with_space_inside_hash_attributes_enabled
      line = '  %div(class="container" id="main")'
      expected = "  %div{ class: 'container', id: 'main' }"
      config_linters = { "SpaceInsideHashAttributes" => { "enabled" => true, "style" => "space" } }

      assert_equal expected, @autocorrector.autocorrect(line, config_linters: config_linters)
    end

    def test_autocorrect_with_space_inside_hash_attributes_enabled_with_no_space_style
      line = '  %div(class="container" id="main")'
      expected = "  %div{class: 'container', id: 'main'}"
      config_linters = { "SpaceInsideHashAttributes" => { "enabled" => true, "style" => "no_space" } }

      assert_equal expected, @autocorrector.autocorrect(line, config_linters: config_linters)
    end

    def test_autocorrect_with_space_inside_hash_attributes_disabled
      line = '  %div(class="container" id="main")'
      expected = "  %div{class: 'container', id: 'main'}"
      config_linters = { "SpaceInsideHashAttributes" => { "enabled" => false, "style" => "space" } }

      assert_equal expected, @autocorrector.autocorrect(line, config_linters: config_linters)
    end
  end
end
