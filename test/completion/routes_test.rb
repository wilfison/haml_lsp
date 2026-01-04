# frozen_string_literal: true

require "test_helper"

module Completion
  class RoutesTest < Minitest::Test
    def setup
      @store = HamlLsp::Store.new

      @rails_routes = {
        "users" => {
          prefix: "users",
          controller: "users",
          params: [],
          verbs: ["GET"],
          uri: "/users",
          source_location: "/rails/my_app/config/routes.rb:33"
        },
        "user" => {
          prefix: "user",
          controller: "users",
          params: ["id"],
          verbs: ["GET"],
          uri: "/users/:id",
          source_location: "/rails/my_app/config/routes.rb:33"
        },
        "posts" => {
          prefix: "posts",
          controller: "posts",
          params: [],
          verbs: ["GET"],
          uri: "/posts",
          source_location: "/rails/my_app/config/routes.rb:33"
        },
        "post_comment" => {
          prefix: "post_comment",
          controller: "posts/comments",
          params: %w[post_id id],
          verbs: ["GET"],
          uri: "/posts/:post_id/comments",
          source_location: "/rails/my_app/config/routes.rb:33"
        }
      }
    end

    def test_handle_returns_empty_array_when_routes_cache_is_nil
      request = create_request("= link_to", 0, 11, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "", nil)

      assert_empty result
    end

    def test_handle_returns_empty_array_when_routes_cache_is_empty
      request = create_request("= link_to", 0, 11, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "", [])

      assert_empty result
    end

    def test_handle_returns_empty_array_when_document_not_found
      request = create_request("= link_to", 0, 11, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "", @rails_routes)

      assert_empty result
    end

    def test_handle_returns_empty_array_when_line_does_not_match_regexp
      request = create_request("= some_method", 0, 13, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "", @rails_routes)

      assert_empty result
    end

    def test_handle_returns_completion_items_when_line_matches_link_to
      request = create_request("= link_to", 0, 11, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "= link_to", @rails_routes)

      assert_equal 4, result.length
      assert_equal "users", result[0][:label]
      assert_equal "user", result[1][:label]
      assert_equal "posts", result[2][:label]
      assert_equal "post_comment", result[3][:label]
    end

    def test_handle_returns_completion_items_when_line_matches_redirect_to
      request = create_request("redirect_to", 0, 11, "/app/controllers/users_controller.rb")
      result = HamlLsp::Completion::Routes.completion_items(request, "redirect_to", @rails_routes)

      assert_equal 4, result.length
    end

    def test_handle_preselects_route_with_matching_controller
      request = create_request("= link_to", 0, 11, "/app/views/users/index.html.haml")
      result = HamlLsp::Completion::Routes.completion_items(request, "= link_to", @rails_routes)

      # Users routes should be preselected since we're in users view
      preselected = result.find { |item| item[:preselect] == true }

      assert_equal "users", preselected[:label]
    end

    def test_build_route_helper_snippet_without_params
      snippet = HamlLsp::Completion::Routes.build_route_helper_snippet(@rails_routes["posts"])

      assert_equal "posts_${1|path,url|}", snippet
    end

    def test_build_route_helper_snippet_with_params
      snippet = HamlLsp::Completion::Routes.build_route_helper_snippet(@rails_routes["user"])

      assert_equal "user_${1|path,url|}(${2:@users})", snippet
    end

    def test_build_route_helper_snippet_with_multiple_params
      snippet = HamlLsp::Completion::Routes.build_route_helper_snippet(@rails_routes["post_comment"])

      assert_equal "post_comment_${1|path,url|}(${2:post_id}, ${3:@comments})", snippet
    end

    def test_match_score_returns_zero_for_no_match
      score = HamlLsp::Completion::Routes.match_score("users", "posts")

      assert_equal 0, score
    end

    def test_match_score_returns_one_for_partial_match
      score = HamlLsp::Completion::Routes.match_score("users/posts", "users/comments")

      assert_equal 1, score
    end

    def test_match_score_returns_full_count_for_complete_match
      score = HamlLsp::Completion::Routes.match_score("users/posts", "users/posts")

      assert_equal 2, score
    end

    def test_extract_current_controller_from_view_path
      controller = HamlLsp::Completion::Routes.extract_current_controller("/app/views/users/index.html.haml")

      assert_equal "users", controller
    end

    def test_extract_current_controller_from_controller_path
      controller = HamlLsp::Completion::Routes.extract_current_controller("/app/controllers/posts_controller.rb")

      assert_equal "posts", controller
    end

    private

    def create_request(_content, line, character, path)
      HamlLsp::Message::Request.new(
        id: 1,
        method: "textDocument/completion",
        params: {
          textDocument: { uri: "file://#{path}" },
          position: { line: line, character: character }
        }
      )
    end
  end
end
