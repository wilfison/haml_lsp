# frozen_string_literal: true

require "test_helper"

class HamlLspTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HamlLsp::VERSION
  end

  def test_version_is_string
    assert_instance_of String, ::HamlLsp::VERSION
  end
end
