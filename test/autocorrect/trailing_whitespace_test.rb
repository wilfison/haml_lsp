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
      corrected_content = @autocorrector.autocorrect(content, config: {})

      assert_equal(expected_content, corrected_content)
    end

    def test_handles_empty_string
      assert_equal "", @autocorrector.autocorrect("")
    end

    def test_handles_only_whitespace
      assert_equal "", @autocorrector.autocorrect("   \t  ")
    end

    def test_handles_trailing_tabs
      assert_equal "%h1 Hello", @autocorrector.autocorrect("%h1 Hello\t\t")
    end

    def test_preserves_leading_whitespace
      assert_equal "  %p text", @autocorrector.autocorrect("  %p text   ")
    end

    def test_does_not_modify_content_without_trailing_whitespace
      content = "%div"
      expected_content = content.dup
      corrected_content = @autocorrector.autocorrect(content, config: {})

      assert_equal(expected_content, corrected_content)
    end
  end
end
