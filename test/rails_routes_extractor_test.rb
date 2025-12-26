# frozen_string_literal: true

require "test_helper"

class RailsRoutesExtractorTest < Minitest::Test
  def test_parse_routes_with_valid_output
    output = <<~ROUTES
                Prefix Verb   URI Pattern                  Controller#Action
         users_path GET    /users(.:format)          users#index
      new_user_path GET    /users/new(.:format)      users#new
          user_path GET    /users/:id(.:format)      users#show
                    POST   /users(.:format)          users#create
    ROUTES

    routes = HamlLsp::Rails::RoutesExtractor.send(:parse_routes, output)

    assert_equal 3, routes.length
    assert_equal "users_path", routes[0][:label]
    assert_equal "new_user_path", routes[1][:label]
    assert_equal "user_path", routes[2][:label]
    assert_equal "GET /users(.:format)", routes[0][:detail]
  end

  def test_extract_routes_with_invalid_path
    routes = HamlLsp::Rails::RoutesExtractor.extract_routes(nil)

    assert_empty routes
  end

  def test_extract_route_details
    line = "  users_path GET    /users(.:format)          users#index"
    detail = HamlLsp::Rails::RoutesExtractor.send(:extract_route_details, line)

    assert_equal "GET /users(.:format)", detail
  end
end
