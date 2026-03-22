# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module HamlLsp
  module References
    class ProviderTest < Minitest::Test
      def setup
        @provider = Provider.new
        @store = HamlLsp::Store.new
        @tmpdir = Dir.mktmpdir
        @views_path = File.join(@tmpdir, "app", "views")
        FileUtils.mkdir_p(File.join(@views_path, "users"))
        FileUtils.mkdir_p(File.join(@views_path, "shared"))
      end

      def teardown
        FileUtils.rm_rf(@tmpdir)
      end

      def test_finds_references_across_files
        File.write(File.join(@views_path, "users", "index.haml"), <<~HAML)
          %h1 Users
          = render "shared/header"
        HAML
        File.write(File.join(@views_path, "users", "show.haml"), <<~HAML)
          = render "shared/header"
          %p User details
        HAML
        File.write(File.join(@views_path, "shared", "_header.haml"), "%h2 Header\n")

        content = "= render \"shared/header\"\n"
        @store.set("file:///current.haml", content)
        document = @store.get("file:///current.haml")

        request = MockRequest.new(
          method: "textDocument/references",
          document_uri: "file:///current.haml",
          params: { position: { line: 0, character: 15 } }
        )

        locations = @provider.handle(request, document, @tmpdir)

        assert_equal 2, locations.size

        uris = locations.map(&:uri)

        assert(uris.any? { |u| u.include?("users/index.haml") })
        assert(uris.any? { |u| u.include?("users/show.haml") })
      end

      def test_no_references_on_non_render_line
        content = "%h1 Title\n"
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/references",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 5 } }
        )

        locations = @provider.handle(request, document, @tmpdir)

        assert_empty locations
      end

      def test_references_without_root_uri
        content = "= render \"shared/header\"\n"
        @store.set("file:///test.haml", content)
        document = @store.get("file:///test.haml")

        request = MockRequest.new(
          method: "textDocument/references",
          document_uri: "file:///test.haml",
          params: { position: { line: 0, character: 15 } }
        )

        locations = @provider.handle(request, document, nil)

        assert_empty locations
      end

      def test_references_only_match_same_partial
        File.write(File.join(@views_path, "users", "index.haml"), <<~HAML)
          = render "shared/header"
          = render "shared/footer"
        HAML

        content = "= render \"shared/header\"\n"
        @store.set("file:///current.haml", content)
        document = @store.get("file:///current.haml")

        request = MockRequest.new(
          method: "textDocument/references",
          document_uri: "file:///current.haml",
          params: { position: { line: 0, character: 15 } }
        )

        locations = @provider.handle(request, document, @tmpdir)

        assert_equal 1, locations.size
        assert_includes locations[0].uri, "users/index.haml"
      end

      def test_reference_locations_have_correct_ranges
        File.write(File.join(@views_path, "users", "index.haml"), <<~HAML)
          %h1 Title
          = render "shared/header"
        HAML

        content = "= render \"shared/header\"\n"
        @store.set("file:///current.haml", content)
        document = @store.get("file:///current.haml")

        request = MockRequest.new(
          method: "textDocument/references",
          document_uri: "file:///current.haml",
          params: { position: { line: 0, character: 15 } }
        )

        locations = @provider.handle(request, document, @tmpdir)

        assert_equal 1, locations.size
        assert_equal 1, locations[0].range.start.line
        assert_equal 10, locations[0].range.start.character
        assert_equal 23, locations[0].range.end.character
      end
    end
  end
end
