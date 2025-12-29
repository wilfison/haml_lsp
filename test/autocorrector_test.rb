# frozen_string_literal: true

require_relative "test_helper"
require "ostruct"

class AutocorrectorTest < Minitest::Test
  def setup
    @autocorrector = HamlLsp::Autocorrector.new
  end

  def test_autocorrectable_returns_true_for_rubocop_diagnostics
    diagnostic = { source: "rubocop" }

    assert @autocorrector.autocorrectable?(diagnostic)
  end

  def test_autocorrectable_returns_false_for_haml_lint_diagnostics
    diagnostic = { source: "haml_lint" }

    refute @autocorrector.autocorrectable?(diagnostic)
  end

  def test_autocorrectable_returns_false_for_nil_source
    diagnostic = { source: nil }

    refute @autocorrector.autocorrectable?(diagnostic)
  end
end
