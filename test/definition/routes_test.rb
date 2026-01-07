# frozen_string_literal: true

require "test_helper"

class DefinitionRoutesTest < Minitest::Test
  def test_extract_route_prefix_from_path_helper
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "users_path")

    assert_equal "users", prefix
  end

  def test_extract_route_prefix_from_url_helper
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "users_url")

    assert_equal "users", prefix
  end

  def test_extract_route_prefix_with_action
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "edit_user_path")

    assert_equal "edit_user", prefix
  end

  def test_extract_route_prefix_with_namespace
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "admin_users_path")

    assert_equal "admin_users", prefix
  end

  def test_extract_route_prefix_returns_nil_for_invalid
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "invalid")

    assert_nil prefix
  end

  def test_extract_route_prefix_returns_nil_for_empty
    prefix = HamlLsp::Definition::Routes.send(:extract_route_prefix, "")

    assert_nil prefix
  end

  def test_find_definition_with_empty_word
    locations = HamlLsp::Definition::Routes.find_definition("", {}, "/tmp")

    assert_empty locations
  end

  def test_find_definition_with_nil_word
    locations = HamlLsp::Definition::Routes.find_definition(nil, {}, "/tmp")

    assert_empty locations
  end

  def test_find_definition_with_non_existent_route
    routes = {
      "users" => {
        prefix: "users",
        controller: "users",
        verbs: ["GET"],
        uri: "/users"
      }
    }

    locations = HamlLsp::Definition::Routes.find_definition("posts_path", routes, "/tmp")

    assert_empty locations
  end

  def test_find_definition_with_invalid_helper_name
    routes = {
      "users" => {
        prefix: "users",
        controller: "users",
        verbs: ["GET"],
        uri: "/users"
      }
    }

    locations = HamlLsp::Definition::Routes.find_definition("invalid", routes, "/tmp")

    assert_empty locations
  end

  def test_find_controller_file_simple
    # Create temporary directory structure for testing
    Dir.mktmpdir do |tmpdir|
      controllers_dir = File.join(tmpdir, "app", "controllers")
      FileUtils.mkdir_p(controllers_dir)
      controller_file = File.join(controllers_dir, "users_controller.rb")
      File.write(controller_file, "class UsersController; end")

      result = HamlLsp::Definition::Routes.send(:find_controller_file, "users", tmpdir)

      assert_equal controller_file, result
    end
  end

  def test_find_controller_file_namespaced
    Dir.mktmpdir do |tmpdir|
      controllers_dir = File.join(tmpdir, "app", "controllers", "admin")
      FileUtils.mkdir_p(controllers_dir)
      controller_file = File.join(controllers_dir, "posts_controller.rb")
      File.write(controller_file, "class Admin::PostsController; end")

      result = HamlLsp::Definition::Routes.send(:find_controller_file, "admin/posts", tmpdir)

      assert_equal controller_file, result
    end
  end

  def test_find_controller_file_non_existent
    Dir.mktmpdir do |tmpdir|
      result = HamlLsp::Definition::Routes.send(:find_controller_file, "nonexistent", tmpdir)

      assert_nil result
    end
  end

  def test_find_action_line
    Dir.mktmpdir do |tmpdir|
      controller_file = File.join(tmpdir, "controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def index
            @users = User.all
          end

          def show
            @user = User.find(params[:id])
          end

          def create
            # action code
          end
        end
      RUBY

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "index")

      assert_equal 1, line # 0-indexed, so line 2 in file is index 1

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "show")

      assert_equal 5, line

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "create")

      assert_equal 9, line
    end
  end

  def test_find_action_line_with_parameters
    Dir.mktmpdir do |tmpdir|
      controller_file = File.join(tmpdir, "controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def update(id)
            # action code
          end
        end
      RUBY

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "update")

      assert_equal 1, line
    end
  end

  def test_find_action_line_with_comment
    Dir.mktmpdir do |tmpdir|
      controller_file = File.join(tmpdir, "controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def destroy # Delete user
            # action code
          end
        end
      RUBY

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "destroy")

      assert_equal 1, line
    end
  end

  def test_find_action_line_non_existent
    Dir.mktmpdir do |tmpdir|
      controller_file = File.join(tmpdir, "controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def index
            @users = User.all
          end
        end
      RUBY

      line = HamlLsp::Definition::Routes.send(:find_action_line, controller_file, "nonexistent")

      assert_nil line
    end
  end

  def test_find_controller_action_location_integration
    Dir.mktmpdir do |tmpdir|
      # Create controller file
      controllers_dir = File.join(tmpdir, "app", "controllers")
      FileUtils.mkdir_p(controllers_dir)
      controller_file = File.join(controllers_dir, "users_controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def index
            @users = User.all
          end
        end
      RUBY

      route = { controller: "users", controller_action: "index" }
      locations = HamlLsp::Definition::Routes.send(
        :find_controller_action_location,
        route,
        tmpdir
      )

      assert_equal 1, locations.size
      location = locations.first

      assert_equal "file://#{controller_file}", location.uri
      assert_equal 1, location.range.start.line
      assert_equal 0, location.range.start.character
    end
  end

  def test_find_definition_integration
    # rubocop:disable Metrics/BlockLength
    Dir.mktmpdir do |tmpdir|
      # Create controller file
      controllers_dir = File.join(tmpdir, "app", "controllers")
      FileUtils.mkdir_p(controllers_dir)
      controller_file = File.join(controllers_dir, "users_controller.rb")
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def index
            @users = User.all
          end

          def edit
            @user = User.find(params[:id])
          end
        end
      RUBY

      routes = {
        "users" => {
          prefix: "users",
          controller: "users",
          controller_action: "index",
          verbs: %w[GET POST],
          uri: "/users"
        },
        "edit_user" => {
          prefix: "edit_user",
          controller: "users",
          controller_action: "edit",
          verbs: ["GET"],
          uri: "/users/:id/edit"
        }
      }

      # Test users_path
      locations = HamlLsp::Definition::Routes.find_definition("users_path", routes, tmpdir)

      assert_equal 1, locations.size
      assert_equal "file://#{controller_file}", locations.first.uri
      assert_equal 1, locations.first.range.start.line

      # Test edit_user_path
      locations = HamlLsp::Definition::Routes.find_definition("edit_user_path", routes, tmpdir)

      assert_equal 1, locations.size
      assert_equal "file://#{controller_file}", locations.first.uri
      assert_equal 5, locations.first.range.start.line
    end
    # rubocop:enable Metrics/BlockLength
  end
end
