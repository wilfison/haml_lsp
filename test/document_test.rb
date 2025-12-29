# frozen_string_literal: true

require "test_helper"

module HamlLsp
  class DocumentTest < Minitest::Test
    def setup
      @uri = "file:///test.haml"
      @content = "%h1 Hello World"
      @document = HamlLsp::Document.new(uri: @uri, content: @content)
    end

    def test_initialization
      assert_equal @uri, @document.uri
      assert_equal @content, @document.content
      assert_empty @document.diagnostics
    end

    def test_update_content
      new_content = "%h2 Updated content"
      @document.update_content(new_content)

      assert_equal new_content, @document.content
      assert_equal @uri, @document.uri
    end

    def test_update_diagnostics
      diagnostics = [
        LanguageServer::Protocol::Interface::Diagnostic.new(
          range: LanguageServer::Protocol::Interface::Range.new(
            start: LanguageServer::Protocol::Interface::Position.new(line: 0, character: 0),
            end: LanguageServer::Protocol::Interface::Position.new(line: 0, character: 5)
          ),
          severity: 1,
          message: "Test error",
          source: "test"
        )
      ]

      @document.update_diagnostics(diagnostics)

      assert_equal diagnostics, @document.diagnostics
    end

    def test_update_diagnostics_with_nil
      @document.update_diagnostics(nil)

      assert_empty @document.diagnostics
    end

    def test_diagnostics_starts_empty
      document = HamlLsp::Document.new(uri: "file:///new.haml", content: "")

      assert_empty document.diagnostics
    end
  end
end
