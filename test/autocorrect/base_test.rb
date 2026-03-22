# frozen_string_literal: true

require "test_helper"

module Autocorrect
  class BaseTest < Minitest::Test
    def setup
      @linter = HamlLsp::Linter.new(root_uri: FIXTURES_PATH)
      @autocorrector = HamlLsp::Autocorrect::Base.new(linter: @linter)
    end

    def test_autocorrectable_diagnostics_filters_correctly
      diagnostics = [
        { source: "rubocop", message: "Trailing whitespace detected." },
        { source: "haml_lint", message: "Line is too long." },
        { source: "rubocop", message: "Classes should be before IDs." }
      ]

      autocorrectable = HamlLsp::Autocorrect::Base.autocorrectable_diagnostics(diagnostics)

      assert_equal(2, autocorrectable.size)
      assert_equal("rubocop", autocorrectable[0][:source])
      assert_equal("rubocop", autocorrectable[1][:source])
    end

    def test_autocorrectable_checks_source
      diagnostic_rubocop = { source: "rubocop", message: "Some lint." }
      diagnostic_haml_lint = { source: "haml_lint", message: "Some lint." }

      assert(HamlLsp::Autocorrect::Base.autocorrectable?(diagnostic_rubocop))
      refute(HamlLsp::Autocorrect::Base.autocorrectable?(diagnostic_haml_lint))
    end

    def test_autocorrectable_returns_false_for_empty_diagnostics
      assert_empty HamlLsp::Autocorrect::Base.autocorrectable_diagnostics([])
    end

    def test_autocorrect_handles_empty_content
      corrected = @autocorrector.autocorrect("/tmp/test.haml", "")

      assert_instance_of String, corrected
    end

    def test_autocorrect_handles_nil_content
      corrected = @autocorrector.autocorrect("/tmp/test.haml", nil)

      assert_instance_of String, corrected
    end

    def test_autocorrect_handles_unicode_content
      content = "%h1 Héllo Wörld 🎉"
      corrected = @autocorrector.autocorrect("/tmp/test.haml", content)

      assert_includes corrected, "Héllo"
      assert_includes corrected, "Wörld"
    end

    def test_autocorrect_applies_rubocop_and_row_by_row_fixes
      file_path = "#{FIXTURES_PATH}/sample_with_issues.haml"
      file_content = File.read(file_path)

      corrected_content = @autocorrector.autocorrect(file_path, file_content)
      expected_content = File.read("#{FIXTURES_PATH}/sample_corrected.haml")

      assert_equal(expected_content, corrected_content)
    end
  end
end
