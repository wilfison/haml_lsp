# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Highlight
    class ProviderTest < Minitest::Test
      def setup
        @provider = Provider.new
        @store = HamlLsp::Store.new
      end

      def test_highlights_partial_references_in_document
        content = <<~HAML
          %h1 Title
          = render "shared/header"
          %p Some content
          = render "shared/header"
        HAML
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/documentHighlight",
          document_uri: "file:///test.haml",
          params: { position: { line: 1, character: 15 } }
        )

        highlights = @provider.handle(request, document)

        assert_equal 2, highlights.size
        assert_equal 1, highlights[0].range.start.line
        assert_equal 3, highlights[1].range.start.line
        # Verify range covers the partial name
        assert_equal 10, highlights[0].range.start.character
        assert_equal 23, highlights[0].range.end.character
      end

      def test_no_highlights_on_non_render_line
        content = <<~HAML
          %h1 Title
          %p Some content
        HAML
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/documentHighlight",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 5 } }
        )

        highlights = @provider.handle(request, document)

        assert_empty highlights
      end

      def test_highlights_only_matching_partial
        content = <<~HAML
          = render "shared/header"
          = render "shared/footer"
          = render "shared/header"
        HAML
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/documentHighlight",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 15 } }
        )

        highlights = @provider.handle(request, document)

        assert_equal 2, highlights.size
        assert_equal 0, highlights[0].range.start.line
        assert_equal 2, highlights[1].range.start.line
      end

      def test_highlights_with_partial_keyword
        content = <<~HAML
          = render partial: "shared/header"
          = render(partial: "shared/header")
        HAML
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/documentHighlight",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 25 } }
        )

        highlights = @provider.handle(request, document)

        assert_equal 2, highlights.size
      end

      def test_highlight_kind_is_read
        content = "= render \"shared/header\"\n"
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/documentHighlight",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 15 } }
        )

        highlights = @provider.handle(request, document)

        assert_equal 1, highlights.size
        assert_equal HamlLsp::Constant::DocumentHighlightKind::READ, highlights[0].kind
      end
    end
  end
end
