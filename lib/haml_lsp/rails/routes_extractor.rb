# frozen_string_literal: true

module HamlLsp
  module Rails
    # Module to extract Rails routes for autocompletion
    module RoutesExtractor
      class << self
        def extract_routes(root_path)
          return [] unless root_path

          routes_output = fetch_routes_output(root_path)
          parse_routes(routes_output)
        rescue StandardError => e
          warn("[haml-lsp] Error extracting routes: #{e.message}")
          []
        end

        private

        def fetch_routes_output(root_path)
          cmd = "bundle exec rails routes"

          Dir.chdir(root_path) do
            `#{cmd} 2>/dev/null`
          end
        end

        def parse_routes(output)
          routes = []
          output.each_line do |line|
            # Parse lines like: "users_path GET /users(.:format) users#index"
            # or "new_user_path GET /users/new(.:format) users#new"
            next unless line =~ /^\s*(\w+_path|\w+_url)\s/

            route_name = ::Regexp.last_match(1)
            routes << {
              label: route_name,
              kind: 6, # Method completion kind
              detail: extract_route_details(line),
              documentation: line.strip
            }
          end
          routes.uniq { |r| r[:label] }
        end

        def extract_route_details(line)
          # Extract HTTP method and path
          if line =~ %r{\s+(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(/\S+)}
            "#{::Regexp.last_match(1)} #{::Regexp.last_match(2)}"
          else
            "Rails Route"
          end
        end
      end
    end
  end
end
