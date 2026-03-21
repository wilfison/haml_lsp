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

    def test_apply_changes_full_replacement
      @document.apply_changes([{ text: "%h2 Replaced" }])

      assert_equal "%h2 Replaced", @document.content
    end

    def test_apply_changes_incremental_single_line_edit
      document = HamlLsp::Document.new(uri: @uri, content: "%h1 Hello World\n")

      change = {
        range: { start: { line: 0, character: 4 }, end: { line: 0, character: 15 } },
        text: "Goodbye"
      }
      document.apply_changes([change])

      assert_equal "%h1 Goodbye\n", document.content
    end

    def test_apply_changes_incremental_insert
      document = HamlLsp::Document.new(uri: @uri, content: "%h1 Hello\n%p World\n")

      change = {
        range: { start: { line: 1, character: 0 }, end: { line: 1, character: 0 } },
        text: "%span New\n"
      }
      document.apply_changes([change])

      assert_equal "%h1 Hello\n%span New\n%p World\n", document.content
    end

    def test_apply_changes_incremental_multiline_delete
      document = HamlLsp::Document.new(uri: @uri, content: "%h1 Line1\n%h2 Line2\n%h3 Line3\n")

      change = {
        range: { start: { line: 0, character: 4 }, end: { line: 2, character: 4 } },
        text: ""
      }
      document.apply_changes([change])

      assert_equal "%h1 Line3\n", document.content
    end

    def test_apply_changes_multiple_incremental
      document = HamlLsp::Document.new(uri: @uri, content: "%h1 AAA\n%h2 BBB\n")

      changes = [
        {
          range: { start: { line: 0, character: 4 }, end: { line: 0, character: 7 } },
          text: "XXX"
        },
        {
          range: { start: { line: 1, character: 4 }, end: { line: 1, character: 7 } },
          text: "YYY"
        }
      ]
      document.apply_changes(changes)

      assert_equal "%h1 XXX\n%h2 YYY\n", document.content
    end
  end
end
