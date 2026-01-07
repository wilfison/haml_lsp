# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class LeadingCommentSpaceTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::LeadingCommentSpace
    end

    def test_autocorrect_adds_space_after_leading_comment
      line = "  -#This is a comment\n"
      expected_line = "  -# This is a comment\n"

      corrected_line = @autocorrector.autocorrect(line)

      assert_equal expected_line, corrected_line
    end

    def test_autocorrect_does_not_modify_correct_comments
      content = "-# This is a comment"
      corrected_content = @autocorrector.autocorrect(content)

      assert_equal content, corrected_content
    end

    def test_autocorrect_does_not_modify_other_lines
      content = "%div Some content"
      corrected_content = @autocorrector.autocorrect(content)

      assert_equal content, corrected_content
    end
  end
end
