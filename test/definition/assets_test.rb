# frozen_string_literal: true

require "test_helper"

class DefinitionAssetsTest < Minitest::Test
  def setup
    @root_uri = "file:///tmp/test_rails_app"
    @workspace_path = "/tmp/test_rails_app"

    # Create test directory structure
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "assets", "javascripts"))
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "assets", "stylesheets"))
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "javascript"))
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "javascript", "stylesheets"))
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "assets", "images"))
    FileUtils.mkdir_p(File.join(@workspace_path, "app", "assets", "images", "icons"))
    FileUtils.mkdir_p(File.join(@workspace_path, "public", "images"))

    # Create test asset files
    @test_js_file = File.join(@workspace_path, "app", "assets", "javascripts", "application.js")
    @test_css_file = File.join(@workspace_path, "app", "assets", "stylesheets", "application.css")
    @test_ts_file = File.join(@workspace_path, "app", "javascript", "application.ts")
    @test_scss_file = File.join(@workspace_path, "app", "javascript", "stylesheets", "main.scss")
    @test_logo_file = File.join(@workspace_path, "app", "assets", "images", "logo.png")
    @test_icon_file = File.join(@workspace_path, "app", "assets", "images", "icons", "check.svg")
    @test_public_image = File.join(@workspace_path, "public", "images", "banner.jpg")

    FileUtils.touch(@test_js_file)
    FileUtils.touch(@test_css_file)
    FileUtils.touch(@test_ts_file)
    FileUtils.touch(@test_scss_file)
    FileUtils.touch(@test_logo_file)
    FileUtils.touch(@test_icon_file)
    FileUtils.touch(@test_public_image)
  end

  def teardown
    FileUtils.rm_rf(@workspace_path)
  end

  def test_find_definition_with_javascript_include_tag
    line = "= javascript_include_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_js_file
  end

  def test_find_definition_with_stylesheet_link_tag
    line = "= stylesheet_link_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_css_file
  end

  def test_find_definition_with_typescript_file
    line = "= javascript_include_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    file_uris = locations.map { |loc| loc.uri.gsub("file://", "") }

    assert_includes file_uris, @test_ts_file
  end

  def test_find_definition_with_scss_file
    line = "= stylesheet_link_tag 'main'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_scss_file
  end

  def test_find_definition_with_vite_javascript_tag
    line = "= vite_javascript_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
  end

  def test_find_definition_with_vite_stylesheet_tag
    line = "= vite_stylesheet_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
  end

  def test_find_definition_with_javascript_pack_tag
    line = "= javascript_pack_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
  end

  def test_find_definition_with_stylesheet_pack_tag
    line = "= stylesheet_pack_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
  end

  def test_find_definition_with_double_quotes
    line = '= javascript_include_tag "application"'

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_js_file
  end

  def test_find_definition_with_parentheses
    line = "= javascript_include_tag('application')"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_js_file
  end

  def test_find_definition_returns_empty_for_non_asset_line
    line = "= render partial: 'shared/header'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_empty locations
  end

  def test_find_definition_returns_empty_for_nonexistent_asset
    line = "= javascript_include_tag 'nonexistent'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_empty locations
  end

  def test_find_definition_returns_empty_without_root_uri
    line = "= javascript_include_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, nil)

    assert_empty locations
  end

  def test_find_definition_returns_empty_for_empty_line
    locations = HamlLsp::Definition::Assets.find_definition("", @root_uri)

    assert_empty locations
  end

  def test_location_structure
    line = "= javascript_include_tag 'application'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    refute_empty locations

    location = locations.first

    assert_instance_of HamlLsp::Interface::Location, location
    assert_match %r{^file://}, location.uri
    assert_instance_of HamlLsp::Interface::Range, location.range
    assert_instance_of HamlLsp::Interface::Position, location.range.start
    assert_equal 0, location.range.start.line
    assert_equal 0, location.range.start.character
  end

  def test_find_definition_with_image_tag
    line = "= image_tag 'logo.png'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_image_tag_without_extension
    line = "= image_tag 'logo'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_image_path
    line = "= image_path 'logo.png'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_image_url
    line = "= image_url 'logo.png'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_asset_path_for_image
    line = "= asset_path 'logo.png'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_nested_image
    line = "= image_tag 'icons/check.svg'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_icon_file
  end

  def test_find_definition_with_image_in_public_directory
    line = "= image_tag 'banner.jpg'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    file_uris = locations.map { |loc| loc.uri.gsub("file://", "") }

    assert_includes file_uris, @test_public_image
  end

  def test_find_definition_with_image_tag_double_quotes
    line = '= image_tag "logo.png"'

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_with_image_tag_parentheses
    line = "= image_tag('logo.png')"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_operator locations.length, :>, 0
    assert_includes locations.map { |loc| loc.uri.gsub("file://", "") }, @test_logo_file
  end

  def test_find_definition_returns_empty_for_nonexistent_image
    line = "= image_tag 'nonexistent.png'"

    locations = HamlLsp::Definition::Assets.find_definition(line, @root_uri)

    assert_empty locations
  end
end
