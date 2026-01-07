# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class FinalNewlineTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::FinalNewline
    end

    def test_autocorrects_when_final_newline_missing
      content = ".container#main\n  .header#top\n    %h1 Title"
      expected_corrected_content = ".container#main\n  .header#top\n    %h1 Title\n"

      corrected_content = @autocorrector.autocorrect(content, { "present" => true })

      assert_equal(expected_corrected_content, corrected_content)
    end

    def test_does_not_change_content_when_final_newline_present
      content = ".container#main\n  .header#top\n    %h1 Title\n"
      expected_corrected_content = ".container#main\n  .header#top\n    %h1 Title\n"

      corrected_content = @autocorrector.autocorrect(content, { "present" => true })

      assert_equal(expected_corrected_content, corrected_content)
    end

    def test_removes_final_newline_when_not_required
      content = ".container#main\n  .header#top\n    %h1 Title\n"
      expected_corrected_content = ".container#main\n  .header#top\n    %h1 Title"

      corrected_content = @autocorrector.autocorrect(content, { "present" => false })

      assert_equal(expected_corrected_content, corrected_content)
    end
  end
end
