# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class TrailingEmptyLinesTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::TrailingEmptyLines
    end

    def test_autocorrects_trailing_empty_lines
      content = "%div\n  %p Hello, World!\n\n\n"
      corrected_content = @autocorrector.autocorrect(content, config: {})

      assert_equal("%div\n  %p Hello, World!", corrected_content)
    end

    def test_does_not_modify_content_without_trailing_empty_lines
      content = "%div\n\n  %p Hello, World!"
      corrected_content = @autocorrector.autocorrect(content, config: {})

      assert_equal(content, corrected_content)
    end
  end
end
