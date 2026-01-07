# frozen_string_literal: true

module HamlLsp
  module Definition
    # Module to provide Rails routes definition lookups
    module Routes
      class << self
        # Find the definition location for a Rails route helper
        # @param word [String] The word under cursor (e.g., "users_path", "edit_user_path")
        # @param rails_routes [Hash] Cached Rails routes
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::Location>] List of definition locations
        def find_definition(word, rails_routes, root_uri)
          return [] if word.nil? || word.empty?

          # Extract route prefix from helper name (remove _path or _url suffix)
          route_prefix = extract_route_prefix(word)
          return [] if route_prefix.nil?

          # Find matching route
          route = rails_routes[route_prefix]
          return [] if route.nil?

          # Get controller and action
          controller_action = route[:controller_action]
          return [] if controller_action.nil? || controller_action.empty?

          # Find controller file and action method
          find_controller_action_location(route, root_uri)
        end

        private

        # Extract route prefix from helper name
        # Examples:
        #   "users_path" -> "users"
        #   "edit_user_url" -> "edit_user"
        #   "new_admin_post_path" -> "new_admin_post"
        def extract_route_prefix(helper_name)
          # Match _path or _url at the end
          match = helper_name.match(/^(.+?)_(path|url)$/)
          return nil unless match

          match[1]
        end

        # Find the location of controller action
        # @param controller_action [String] Format: "controller#action" (e.g., "users#index")
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::Location>] List of locations
        def find_controller_action_location(route, root_uri)
          controller_name = route[:controller]
          action_name = route[:controller_action]

          controller_file = find_controller_file(controller_name, root_uri)
          return [] unless controller_file && File.exist?(controller_file)

          line_number = find_action_line(controller_file, action_name)
          return [] unless line_number

          [
            HamlLsp::Interface::Location.new(
              uri: "file://#{controller_file}",
              range: HamlLsp::Interface::Range.new(
                start: HamlLsp::Interface::Position.new(line: line_number, character: 0),
                end: HamlLsp::Interface::Position.new(line: line_number, character: 0)
              )
            )
          ]
        end

        # Find controller file path
        # @param controller_name [String] Controller name (e.g., "users", "admin/posts")
        # @param root_uri [String] The workspace root URI
        # @return [String, nil] Full path to controller file
        def find_controller_file(controller_name, root_uri)
          # Convert controller name to file path
          # Examples:
          #   "users" -> "app/controllers/users_controller.rb"
          #   "admin/posts" -> "app/controllers/admin/posts_controller.rb"
          controller_path = "#{controller_name}_controller.rb"
          full_path = File.join(root_uri, "app", "controllers", controller_path)

          File.exist?(full_path) ? full_path : nil
        end

        # Find the line number of an action method in a controller file
        # @param controller_file [String] Full path to controller file
        # @param action_name [String] Action method name
        # @return [Integer, nil] Line number (0-indexed for LSP)
        def find_action_line(controller_file, action_name)
          File.readlines(controller_file).each_with_index do |line, index|
            # Match method definition: "def action_name" or "def self.action_name"
            if line.match?(/^\s*def\s+(self\.)?#{Regexp.escape(action_name)}\s*($|\(|#)/)
              return index # LSP uses 0-based line numbers
            end
          end

          nil
        rescue StandardError => e
          HamlLsp.log("Error finding action line: #{e.message}")
          nil
        end
      end
    end
  end
end
