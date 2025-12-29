# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Lint
    class RunnerTest < Minitest::Test
      def setup
        @runner = HamlLsp::Lint::Runner.new
      end

      def test_runner_initialization
        assert_instance_of HamlLsp::Lint::Runner, @runner
      end

      def test_runner_has_document_accessor
        assert_respond_to @runner, :document
        assert_respond_to @runner, :document=
      end
    end
  end
end
