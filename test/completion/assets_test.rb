# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module Completion
  class AssetsTest < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir("haml_lsp_assets_test")
      @root_uri = "file://#{@tmpdir}"

      # Create directory structure
      FileUtils.mkdir_p(File.join(@tmpdir, "app", "assets", "images"))
      FileUtils.mkdir_p(File.join(@tmpdir, "app", "assets", "javascripts"))
      FileUtils.mkdir_p(File.join(@tmpdir, "app", "assets", "stylesheets"))
      FileUtils.mkdir_p(File.join(@tmpdir, "public", "images"))

      # Create test files
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "images", "logo.png"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "images", "logo.svg"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "images", "background.jpg"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "javascripts", "application.js"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "javascripts", "main.coffee"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "stylesheets", "application.css"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "stylesheets", "main.scss"))
      FileUtils.touch(File.join(@tmpdir, "public", "images", "favicon.ico"))
    end

    def teardown
      FileUtils.rm_rf(@tmpdir)
    end

    def test_completion_items_returns_empty_when_root_uri_is_nil
      result = HamlLsp::Completion::Assets.completion_items("= image_tag ", nil)

      assert_empty result
    end

    def test_completion_items_returns_empty_when_no_asset_helper_found
      line = "= something else"
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      assert_empty result
    end

    def test_completion_items_for_image_tag
      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      assert_includes result.map { |item| item[:label] }, "logo.png"
      assert_includes result.map { |item| item[:label] }, "logo.svg"
      assert_includes result.map { |item| item[:label] }, "background.jpg"
      assert_includes result.map { |item| item[:label] }, "favicon.ico"
    end

    def test_completion_items_for_image_path
      line = "= image_path \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "logo.png"
      assert_includes labels, "logo.svg"
    end

    def test_completion_items_for_javascript_include_tag
      line = "= javascript_include_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "application.js"
      assert_includes labels, "main.coffee"
    end

    def test_completion_items_for_stylesheet_link_tag
      line = "= stylesheet_link_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "application.css"
      assert_includes labels, "main.scss"
    end

    def test_completion_items_with_prefix_filter
      line = "= image_tag \"logo"
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "logo.png"
      assert_includes labels, "logo.svg"
      refute_includes labels, "background.jpg"
    end

    def test_completion_items_with_single_quotes
      line = "= image_tag 'logo"
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "logo.png"
    end

    def test_completion_items_with_parentheses
      line = "= image_tag(\"logo"
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "logo.png"
    end

    def test_completion_item_structure
      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      item = result.first

      assert item.key?(:label)
      assert item.key?(:kind)
      assert item.key?(:detail)
      assert item.key?(:documentation)
      assert item.key?(:insert_text)
      assert item.key?(:sort_text)
      assert_equal HamlLsp::Constant::CompletionItemKind::FILE, item[:kind]
    end

    def test_completion_item_detail_for_image
      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      item = result.find { |i| i[:label] == "logo.png" }

      assert_match(/Image asset:/, item[:detail])
    end

    def test_completion_item_detail_for_javascript
      line = "= javascript_include_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      item = result.first

      assert_match(/JavaScript asset:/, item[:detail])
    end

    def test_completion_item_detail_for_stylesheet
      line = "= stylesheet_link_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      item = result.first

      assert_match(/Stylesheet asset:/, item[:detail])
    end

    def test_asset_name_removes_extension_for_javascript
      line = "= javascript_include_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      insert_texts = result.map { |item| item[:insert_text] }

      assert_includes insert_texts, "application"
      refute_includes insert_texts, "application.js"
    end

    def test_asset_name_removes_extension_for_stylesheet
      line = "= stylesheet_link_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      insert_texts = result.map { |item| item[:insert_text] }

      assert_includes insert_texts, "application"
      refute_includes insert_texts, "application.css"
    end

    def test_asset_name_keeps_extension_for_images
      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      labels = result.map { |item| item[:label] }

      assert_includes labels, "logo.png"
    end

    def test_scans_subdirectories
      FileUtils.mkdir_p(File.join(@tmpdir, "app", "assets", "images", "icons"))
      FileUtils.touch(File.join(@tmpdir, "app", "assets", "images", "icons", "menu.svg"))

      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      labels = result.map { |item| item[:label] }

      assert_includes labels, "icons/menu.svg"
    end

    def test_handles_nonexistent_directories_gracefully
      empty_tmpdir = Dir.mktmpdir("haml_lsp_assets_empty_test")
      empty_root_uri = "file://#{empty_tmpdir}"

      line = "= image_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, empty_root_uri)

      assert_empty result

      FileUtils.rm_rf(empty_tmpdir)
    end

    def test_completion_items_for_vite_javascript_tag
      line = "= vite_javascript_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "application.js"
    end

    def test_completion_items_for_vite_stylesheet_tag
      line = "= vite_stylesheet_tag \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      refute_empty result
      labels = result.map { |item| item[:label] }

      assert_includes labels, "application.css"
    end

    def test_completion_items_for_asset_path
      line = "= asset_path \""
      result = HamlLsp::Completion::Assets.completion_items(line, @root_uri)

      # asset_path should return all types of assets
      refute_empty result
    end

    def test_workspace_path_from_uri_with_file_scheme
      path = HamlLsp::Completion::Assets.send(:workspace_path_from_uri, "file:///home/user/project")

      assert_equal "/home/user/project", path
    end

    def test_workspace_path_from_uri_without_scheme
      path = HamlLsp::Completion::Assets.send(:workspace_path_from_uri, "/home/user/project")

      assert_equal "/home/user/project", path
    end

    def test_workspace_path_from_uri_with_encoded_spaces
      path = HamlLsp::Completion::Assets.send(:workspace_path_from_uri, "file:///home/user/my%20project")

      assert_equal "/home/user/my project", path
    end
  end
end
