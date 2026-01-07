# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class ClassesBeforeIdsTest < Minitest::Test
    def setup
      @autocorrector = HamlLsp::Autocorrect::ClassesBeforeIds
    end

    def test_autocorrects_class_before_classes
      content = "#main.container"
      expected_corrected_content = ".container#main"
      corrected_content = @autocorrector.autocorrect(content, { "EnforcedStyle" => "class" })

      assert_equal(expected_corrected_content, corrected_content)
    end

    def test_autocorrects_ids_before_classes
      content = ".container#main"
      expected_corrected_content = "#main.container"
      corrected_content = @autocorrector.autocorrect(content, { "EnforcedStyle" => "id" })

      assert_equal(expected_corrected_content, corrected_content)
    end

    def test_does_not_modify_correct_order
      content = ".container#main"
      expected_corrected_content = ".container#main"
      corrected_content = @autocorrector.autocorrect(content, { "EnforcedStyle" => "class" })

      assert_equal(expected_corrected_content, corrected_content)
    end

    def test_does_not_modify_lines_without_ids_or_classes
      content = "%div"
      expected_corrected_content = "%div"
      corrected_content = @autocorrector.autocorrect(content, { "EnforcedStyle" => "class" })

      assert_equal(expected_corrected_content, corrected_content)
    end
  end
end
