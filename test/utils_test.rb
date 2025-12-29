# frozen_string_literal: true

require "test_helper"

module HamlLsp
  class UtilsTest < Minitest::Test
    def test_interface_constant_exists
      assert_equal LanguageServer::Protocol::Interface, HamlLsp::Interface
    end

    def test_constant_constant_exists
      assert_equal LanguageServer::Protocol::Constant, HamlLsp::Constant
    end

    def test_interface_can_create_position
      position = HamlLsp::Interface::Position.new(line: 1, character: 5)

      assert_instance_of LanguageServer::Protocol::Interface::Position, position
      assert_equal 1, position.attributes[:line]
      assert_equal 5, position.attributes[:character]
    end

    def test_constant_message_type_exists
      assert_equal 1, HamlLsp::Constant::MessageType::ERROR
      assert_equal 2, HamlLsp::Constant::MessageType::WARNING
      assert_equal 3, HamlLsp::Constant::MessageType::INFO
      assert_equal 4, HamlLsp::Constant::MessageType::LOG
    end

    def test_constant_diagnostic_severity_exists
      assert_equal 1, HamlLsp::Constant::DiagnosticSeverity::ERROR
      assert_equal 2, HamlLsp::Constant::DiagnosticSeverity::WARNING
      assert_equal 3, HamlLsp::Constant::DiagnosticSeverity::INFORMATION
      assert_equal 4, HamlLsp::Constant::DiagnosticSeverity::HINT
    end
  end
end
