# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class TrailingWhitespaceTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::TrailingWhitespace
    end

    def test_autocorrects_trailing_empty_lines
      content = "%div         "
      expected_content = "%div"
      corrected_content = @autocorrector.autocorrect(content, {})

      assert_equal(expected_content, corrected_content)
    end

    def test_does_not_modify_content_without_trailing_whitespace
      content = "%div"
      expected_content = content.dup
      corrected_content = @autocorrector.autocorrect(content, {})

      assert_equal(expected_content, corrected_content)
    end
  end
end
