# frozen_string_literal: true

require "test_helper"

class RailsRoutesExtractorTest < Minitest::Test
  def test_parse_routes_with_valid_output
    output = <<~ROUTES
--[ Route 1 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | users
Verb              | GET
URI               | /users(.:format)
Controller#Action | users#index
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 2 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | 
Verb              | POST
URI               | /users(.:format)
Controller#Action | users#create
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 3 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | new_user
Verb              | GET
URI               | /users/new(.:format)
Controller#Action | users#new
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 4 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | edit_user
Verb              | GET
URI               | /users/:id/edit(.:format)
Controller#Action | users#edit
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 5 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | user
Verb              | GET
URI               | /users/:id(.:format)
Controller#Action | users#show
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 6 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | 
Verb              | PATCH
URI               | /users/:id(.:format)
Controller#Action | users#update
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 7 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | 
Verb              | PUT
URI               | /users/:id(.:format)
Controller#Action | users#update
Source Location   | /rails/my_app/config/routes.rb:33
--[ Route 8 ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Prefix            | 
Verb              | DELETE
URI               | /users/:id(.:format)
Controller#Action | users#destroy
Source Location   | /rails/my_app/config/routes.rb:33
    ROUTES

    routes = HamlLsp::Rails::RoutesExtractor.parse_routes(output, "")
    collection_route = routes["users"]
    member_route = routes["user"]

    assert_equal 4, routes.keys.size
    assert_equal "users", collection_route[:prefix]
    assert_equal %w[GET POST], collection_route[:verbs]
    assert_equal "/users(.:format)", collection_route[:uri]
    assert_equal "users", collection_route[:controller]

    assert_equal "user", member_route[:prefix]
    assert_equal %w[GET PATCH PUT DELETE], member_route[:verbs]
    assert_equal "/users/:id(.:format)", member_route[:uri]
    assert_equal "users", member_route[:controller]
  end

  def test_extract_routes_with_invalid_path
    routes = HamlLsp::Rails::RoutesExtractor.extract_routes(nil)

    assert_empty routes
  end

  def test_extract_params
    path = "/users/:id/posts/:post_id(.:format)"
    params = HamlLsp::Rails::RoutesExtractor.extract_params(path)

    assert_equal %w[id post_id], params
  end
end
