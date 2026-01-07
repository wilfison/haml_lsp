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
  end
end
