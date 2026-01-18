# frozen_string_literal: true

module HamlLsp
  module Rails
    # Module to extract Rails routes for autocompletion
    module RoutesExtractor
      LINE_REGEXP = /(?<label>Prefix|Verb|URI|Controller#Action|Source Location)[\s|]+(?<value>\S+)?\n/

      class << self
        def extract_routes(root_path)
          return [] unless root_path

          routes_output = fetch_routes_output(root_path)
          parse_routes(routes_output, root_path)
        end

        def fetch_routes_output(root_path)
          cmd = "bundle exec rails routes --expanded"

          Dir.chdir(root_path) do
            `#{cmd} 2>/dev/null`
          end
        end

        # Parse lines like:
        #     --[ Route 1 ]-----------------------------------------------------------
        #     Prefix            | rails_health_check
        #     Verb              | GET
        #     URI               | /up(.:format)
        #     Controller#Action | rails/health#show
        #     Source Location   | /my_app/config/routes.rb:4
        #
        # @return [Hash{String => Hash}] Parsed routes with prefix as key
        def parse_routes(output, root_path)
          routes = {}
          last_prefix = nil
          output_blocks = output.gsub(Regexp.new("^#{root_path}/"), ".").split(/-+\[[\s\w]+\]-+\s*/)

          output_blocks.each do |route_block|
            next if route_block.strip.empty?

            route = extract_route(route_block, last_prefix)
            next if route.nil?

            if routes[route[:prefix]]
              routes[route[:prefix]][:verbs] << route[:verbs].first
            else
              routes[route[:prefix]] = route
            end

            last_prefix = route[:prefix]
          end

          routes
        end

        def extract_route(route_block, last_prefix)
          matches = route_block.scan(LINE_REGEXP).to_h
          return nil if matches.empty?

          controller_name, controller_action = matches["Controller#Action"].to_s.split("#")

          {
            prefix: matches["Prefix"] || last_prefix,
            verbs: [matches["Verb"]],
            uri: matches["URI"],
            params: extract_params(matches["URI"]),
            controller: controller_name,
            controller_action: controller_action,
            source_location: matches["Source Location"]
          }
        end

        def extract_params(path)
          # Extract params like :id, :user_id from path, but exclude :format
          params = path.scan(/:(\w+)/).flatten
          params.reject { |param| param == "format" }
        end
      end
    end
  end
end
