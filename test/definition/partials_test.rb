# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class DefinitionPartialsTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @views_path = File.join(@tmpdir, "app", "views")
    FileUtils.mkdir_p(@views_path)
    create_test_partials
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_find_definition_with_empty_word
    locations = HamlLsp::Definition::Partials.find_definition("", "/path/to/file.haml", @tmpdir)

    assert_empty locations
  end

  def test_find_definition_with_nil_word
    locations = HamlLsp::Definition::Partials.find_definition(nil, "/path/to/file.haml", @tmpdir)

    assert_empty locations
  end

  def test_find_definition_with_nil_root_uri
    locations = HamlLsp::Definition::Partials.find_definition("header", "/path/to/file.haml", nil)

    assert_empty locations
  end

  def test_extract_partial_name_from_quoted_string
    name = HamlLsp::Definition::Partials.send(:extract_partial_name, '  = render "users/profile"')

    assert_equal "users/profile", name
  end

  def test_extract_partial_name_from_single_quoted_string
    name = HamlLsp::Definition::Partials.send(:extract_partial_name, "%div= render(partial: 'shared/header')")

    assert_equal "shared/header", name
  end

  def test_find_definition_for_simple_partial
    document_path = File.join(@views_path, "users", "index.html.haml")
    locations = HamlLsp::Definition::Partials.find_definition("= render('header')", document_path, @tmpdir)

    assert_equal 1, locations.length
    assert_match(%r{shared/_header\.haml$}, locations[0].uri)
  end

  def test_find_definition_for_namespaced_partial
    document_path = File.join(@views_path, "users", "index.html.haml")
    locations = HamlLsp::Definition::Partials.find_definition("  = render 'users/profile'", document_path, @tmpdir)

    assert_equal 1, locations.length
    assert_match(%r{users/_profile\.haml$}, locations[0].uri)
  end

  def test_find_definition_for_local_partial
    document_path = File.join(@views_path, "users", "index.html.haml")
    locations = HamlLsp::Definition::Partials.find_definition(
      ".container#profile= render 'profile'",
      document_path,
      @tmpdir
    )

    refute_empty locations
    # Should find the local users/_profile.haml
    assert_match(%r{users/_profile\.haml$}, locations[0].uri)
  end

  def test_find_definition_sorts_by_proximity
    # Create partials in different locations
    posts_dir = File.join(@views_path, "posts")
    FileUtils.mkdir_p(posts_dir)
    File.write(File.join(posts_dir, "_card.haml"), ".card")

    admin_dir = File.join(@views_path, "admin")
    FileUtils.mkdir_p(admin_dir)
    File.write(File.join(admin_dir, "_card.haml"), ".card")

    # Search from posts directory
    document_path = File.join(@views_path, "posts", "index.html.haml")
    locations = HamlLsp::Definition::Partials.find_definition("= render partial: 'card'", document_path, @tmpdir)

    # The posts/_card.haml should be first (closer)
    assert_match(%r{posts/_card\.haml$}, locations[0].uri)
  end

  def test_find_exact_partial
    file = HamlLsp::Definition::Partials.send(:find_exact_partial, "shared/header", @views_path)

    assert_equal File.join(@views_path, "shared", "_header.haml"), file
  end

  def test_find_exact_partial_returns_nil_when_not_found
    file = HamlLsp::Definition::Partials.send(:find_exact_partial, "nonexistent/partial", @views_path)

    assert_nil file
  end

  def test_find_in_directory
    shared_dir = File.join(@views_path, "shared")
    file = HamlLsp::Definition::Partials.send(:find_in_directory, "header", shared_dir)

    assert_equal File.join(shared_dir, "_header.haml"), file
  end

  def test_find_in_directory_returns_nil_when_not_found
    shared_dir = File.join(@views_path, "shared")
    file = HamlLsp::Definition::Partials.send(:find_in_directory, "nonexistent", shared_dir)

    assert_nil file
  end

  def test_find_global_partials
    files = HamlLsp::Definition::Partials.send(:find_global_partials, "header", @views_path)

    assert_equal 1, files.length
    assert_match(%r{shared/_header\.haml$}, files[0])
  end

  def test_extract_view_directory_from_views_path
    document_path = File.join(@views_path, "users", "index.html.haml")
    dir = HamlLsp::Definition::Partials.send(:extract_view_directory, document_path, @views_path)

    assert_equal File.join(@views_path, "users"), dir
  end

  def test_extract_view_directory_returns_nil_for_non_view_path
    document_path = "/app/models/user.rb"
    dir = HamlLsp::Definition::Partials.send(:extract_view_directory, document_path, @views_path)

    assert_nil dir
  end

  def test_calculate_score_exact_strategy_higher
    file = File.join(@views_path, "users", "_profile.haml")
    current_dir = File.join(@views_path, "users")
    
    score = HamlLsp::Definition::Partials.send(:calculate_score, file, current_dir, strategy: :exact)

    assert_operator score, :>, 900
  end

  def test_calculate_score_local_strategy
    file = File.join(@views_path, "users", "_profile.haml")
    current_dir = File.join(@views_path, "users")
    
    score = HamlLsp::Definition::Partials.send(:calculate_score, file, current_dir, strategy: :local)

    assert_operator score, :>, 700
  end

  def test_calculate_score_shared_strategy
    file = File.join(@views_path, "shared", "_header.haml")
    current_dir = File.join(@views_path, "users")
    
    score = HamlLsp::Definition::Partials.send(:calculate_score, file, current_dir, strategy: :shared)

    assert_operator score, :>, 300
  end

  def test_calculate_score_with_proximity_bonus
    file1 = File.join(@views_path, "users", "_profile.haml")
    file2 = File.join(@views_path, "admin", "users", "_profile.haml")
    current_dir = File.join(@views_path, "users")
    
    score1 = HamlLsp::Definition::Partials.send(:calculate_score, file1, current_dir, strategy: :global)
    score2 = HamlLsp::Definition::Partials.send(:calculate_score, file2, current_dir, strategy: :global)

    # Closer file should have higher score
    assert_operator score1, :>, score2
  end

  def test_calculate_distance_same_directory
    distance = HamlLsp::Definition::Partials.send(
      :calculate_distance,
      "/app/views/users",
      "/app/views/users"
    )

    assert_equal 0, distance
  end

  def test_calculate_distance_sibling_directories
    distance = HamlLsp::Definition::Partials.send(
      :calculate_distance,
      "/app/views/users",
      "/app/views/posts"
    )

    assert_equal 2, distance
  end

  def test_calculate_distance_nested_directories
    distance = HamlLsp::Definition::Partials.send(
      :calculate_distance,
      "/app/views/users",
      "/app/views/users/posts"
    )

    assert_equal 1, distance
  end

  def test_build_locations_returns_location_objects
    partial_files = [
      {
        file: File.join(@views_path, "shared", "_header.haml"),
        score: 100
      }
    ]

    locations = HamlLsp::Definition::Partials.send(:build_locations, partial_files)

    assert_equal 1, locations.length
    assert_instance_of HamlLsp::Interface::Location, locations[0]
    assert_match(%r{shared/_header\.haml$}, locations[0].uri)
  end

  private

  def create_test_partials
    # Create shared/_header.haml
    shared_dir = File.join(@views_path, "shared")
    FileUtils.mkdir_p(shared_dir)
    File.write(
      File.join(shared_dir, "_header.haml"),
      "-# locals: (title:)\n%h1= title"
    )

    # Create shared/_footer.haml
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
end
