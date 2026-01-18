# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class IndentationTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::Indentation
    end

    def test_autocorrects_tabs_to_spaces_with_default_width
      input = "\t%div"
      expected_output = "  %div"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_autocorrects_multiple_tabs_to_spaces
      input = "\t\t%div"
      expected_output = "    %div"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_autocorrects_spaces_to_tabs
      input = "    %div"
      expected_output = "\t\t\t\t%div"
      config = { "character" => "tab", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_autocorrects_with_custom_width
      input = "\t%div"
      expected_output = "    %div"
      config = { "character" => "space", "width" => 4 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_autocorrects_mixed_tabs_and_spaces
      input = "\t  %div"
      expected_output = "    %div"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_does_not_modify_lines_without_leading_whitespace
      input = "%div"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(input, corrected_content)
    end

    def test_uses_default_config_when_not_provided
      input = "\t%div"
      expected_output = "  %div"

      corrected_content = @autocorrector.autocorrect(input, config: {})

      assert_equal(expected_output, corrected_content)
    end

    def test_preserves_content_after_indentation
      input = "\t\t%div.content Hello World"
      expected_output = "    %div.content Hello World"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end

    def test_handles_deep_indentation_levels
      input = "\t\t\t\t%div"
      expected_output = "        %div"
      config = { "character" => "space", "width" => 2 }

      corrected_content = @autocorrector.autocorrect(input, config: config)

      assert_equal(expected_output, corrected_content)
    end
  end
end
