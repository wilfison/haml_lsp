# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class SpaceBeforeScriptTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::SpaceBeforeScript
    end

    def test_autocorrects_space_before_script
      input = '-puts "Hello"'
      expected_output = '- puts "Hello"'

      corrected_content = @autocorrector.autocorrect(input)

      assert_equal(expected_output, corrected_content)
    end

    def test_does_not_modify_correct_lines
      input = '- puts "Hello"'

      corrected_content = @autocorrector.autocorrect(input)

      assert_equal(input, corrected_content)
    end

    def test_handles_mixed_indentation
      input = '  =  link_to "Home", root_path'
      expected_output = '  = link_to "Home", root_path'

      corrected_content = @autocorrector.autocorrect(input)

      assert_equal(expected_output, corrected_content)
    end
  end
end
