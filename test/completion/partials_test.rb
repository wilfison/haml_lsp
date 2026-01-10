# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module Completion
  class PartialsTest < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir
      @views_path = File.join(@tmpdir, "app", "views")
      FileUtils.mkdir_p(@views_path)
      create_test_partials

      @request = MockRequest.new(
        method: "textDocument/didClose",
        document_uri: "file://#{@views_path}/users/index.html.haml",
        document_uri_path: "#{@views_path}/users/index.html.haml",
        params: {
          position: { line: 10, character: 5 },
          textDocument: { uri: "file://#{@views_path}/users/index.html.haml" }
        }
      )
    end

    def teardown
      FileUtils.rm_rf(@tmpdir)
    end

    def test_completion_items_returns_empty_when_root_uri_is_nil
      result = HamlLsp::Completion::Partials.completion_items(@request, "= render(", nil)

      assert_empty result
    end

    def test_completion_items_returns_empty_when_line_does_not_match_render
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        "= some_method",
        @tmpdir
      )

      assert_empty result
    end

    def test_completion_items_returns_partials_for_render_with_quotes
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        "= render('",
        @tmpdir
      )

      assert_operator result.length, :>, 0
      labels = result.map { |item| item[:label] }

      assert_includes labels, "shared/header"
      assert_includes labels, "users/profile"
    end

    def test_completion_items_returns_partials_for_render_with_partial_keyword
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        '= render(partial: "',
        @tmpdir
      )

      assert_operator result.length, :>, 0
      labels = result.map { |item| item[:label] }

      assert_includes labels, "shared/header"
    end

    def test_completion_items_includes_locals_in_snippet
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        "= render('",
        @tmpdir
      )

      # Find the header partial (has locals)
      header_item = result.find { |item| item[:label] == "shared/header" }

      refute_nil header_item

      # Should include locals in snippet
      assert_match(/title:/, header_item[:text_edit][:new_text])
      assert_match(/subtitle:/, header_item[:text_edit][:new_text])
    end

    def test_completion_items_simple_snippet_for_no_locals
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        "= render(\"",
        @tmpdir
      )

      # Find the footer partial (no locals)
      footer_item = result.find { |item| item[:label] == "shared/footer" }

      refute_nil footer_item

      # Should be simple snippet without locals
      assert_equal '"shared/footer"', footer_item[:text_edit][:new_text]
    end

    def test_completion_items_preselects_closest_partial
      result = HamlLsp::Completion::Partials.completion_items(
        @request,
        "= render('",
        @tmpdir
      )

      # The users/profile partial should be closer than shared/header
      preselected = result.find { |item| item[:preselect] == true }

      refute_nil preselected

      # Should be the first item (sorted by distance)
      assert_equal result.first[:label], preselected[:label]
    end

    # Testing through public API - private methods are implementation details

    private

    def create_test_partials
      # Create shared/_header.haml with locals
      shared_dir = File.join(@views_path, "shared")
      FileUtils.mkdir_p(shared_dir)
      File.write(
        File.join(shared_dir, "_header.haml"),
        "-# locals: (title:, subtitle: nil)\n%h1= title"
      )

      # Create shared/_footer.haml without locals
      File.write(
        File.join(shared_dir, "_footer.haml"),
        "%footer Copyright 2024"
      )

      # Create users/_profile.haml
      users_dir = File.join(@views_path, "users")
      FileUtils.mkdir_p(users_dir)
      File.write(
        File.join(users_dir, "_profile.haml"),
        "-# locals: (user:)\n.profile= user.name"
      )
    end

    def create_partial_with_locals(name, locals_comment)
      dir = File.join(@views_path, "test")
      FileUtils.mkdir_p(dir)
      file = File.join(dir, "_#{name}.haml")
      File.write(file, "#{locals_comment}\n.content")
      file
    end
  end
end
