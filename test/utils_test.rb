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

    def test_word_at_position_extracts_simple_word
      content = "hello world"
      word = HamlLsp::Utils.word_at_position(content, 0, 3)

      assert_equal "hello", word
    end

    def test_word_at_position_extracts_word_at_start
      content = "hello world"
      word = HamlLsp::Utils.word_at_position(content, 0, 0)

      assert_equal "hello", word
    end

    def test_word_at_position_extracts_word_at_end
      content = "hello world"
      word = HamlLsp::Utils.word_at_position(content, 0, 10)

      assert_equal "world", word
    end

    def test_word_at_position_extracts_word_with_underscore
      content = "users_path"
      word = HamlLsp::Utils.word_at_position(content, 0, 5)

      assert_equal "users_path", word
    end

    def test_word_at_position_extracts_word_with_numbers
      content = "user123"
      word = HamlLsp::Utils.word_at_position(content, 0, 4)

      assert_equal "user123", word
    end

    def test_word_at_position_from_multiline_content
      content = "line one\nline two\nline three"
      word = HamlLsp::Utils.word_at_position(content, 1, 5)

      assert_equal "two", word
    end

    def test_word_at_position_with_rails_helper
      content = "  = link_to 'Show User', user_path(@user)"
      word = HamlLsp::Utils.word_at_position(content, 0, 29)

      assert_equal "user_path", word
    end

    def test_word_at_position_returns_nil_for_invalid_line
      content = "hello world"
      word = HamlLsp::Utils.word_at_position(content, 5, 0)

      assert_nil word
    end

    def test_word_at_position_returns_nil_for_invalid_character
      content = "hello"
      word = HamlLsp::Utils.word_at_position(content, 0, 100)

      assert_nil word
    end

    def test_word_at_position_at_space_returns_previous_word
      content = "hello world"
      word = HamlLsp::Utils.word_at_position(content, 0, 5)

      # When cursor is on a space, it returns the word to the left
      assert_equal "hello", word
    end

    def test_word_at_position_returns_nil_for_nil_content
      word = HamlLsp::Utils.word_at_position(nil, 0, 0)

      assert_nil word
    end

    def test_word_at_position_returns_nil_for_empty_content
      word = HamlLsp::Utils.word_at_position("", 0, 0)

      assert_nil word
    end

    def test_word_at_position_with_special_characters_around
      content = "link_to('users', users_path)"
      word = HamlLsp::Utils.word_at_position(content, 0, 20)

      assert_equal "users_path", word
    end

    def test_word_at_position_extracts_edit_user_path
      content = "= link_to 'Edit', edit_user_path(@user)"
      word = HamlLsp::Utils.word_at_position(content, 0, 23)

      assert_equal "edit_user_path", word
    end

    def test_word_at_position_on_first_character_of_word
      content = "users_path"
      word = HamlLsp::Utils.word_at_position(content, 0, 0)

      assert_equal "users_path", word
    end

    def test_word_at_position_on_last_character_of_word
      content = "users_path"
      word = HamlLsp::Utils.word_at_position(content, 0, 9)

      assert_equal "users_path", word
    end
  end
end
