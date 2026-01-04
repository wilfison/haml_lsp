# frozen_string_literal: true

module HamlLsp
  module Completion
    # Module to provide Rails routes completions
    module Routes
      # Regexp to match Rails route helper keywords in the line
      LINE_REGEXP = /(?:link_to|redirect_to|button_to|form_for|visit|url|path|href)/

      class << self
        # Handles completion requests
        # @param request [HamlLsp::Message::Request] The completion request 'textDocument/completion'
        # @param line [String] The current line content
        # @param rails_routes [Array<Hash>] Cached Rails routes for autocompletion
        # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
        def completion_items(request, line, rails_routes)
          return [] if rails_routes.nil? || rails_routes.empty?

          # Check if the line contains route helper keywords
          return [] unless line.match?(LINE_REGEXP)

          build_completion_items(request.document_uri_path, rails_routes)
        end

        def build_completion_items(document_uri_path, rails_routes)
          current_controller = extract_current_controller(document_uri_path)

          items_with_score = rails_routes.map do |_prefix, route|
            item = build_completion_item(route)
            score = match_score(current_controller, route[:controller] || "")

            { item: item, score: score }
          end

          # Find and mark the item with highest score as preselected
          unless items_with_score.empty?
            max_score = items_with_score.map { |iws| iws[:score] }.max
            max_score_item = items_with_score.find { |iws| iws[:score] == max_score }
            max_score_item[:item][:preselect] = true if max_score_item
          end

          items_with_score.map { |iws| iws[:item] }
        end

        def build_completion_item(route)
          snippet = build_route_helper_snippet(route)

          {
            label: route[:prefix],
            kind: Constant::CompletionItemKind::METHOD,
            detail: "#{route[:verbs].join("|")} #{route[:uri]}",
            documentation: "Defined in #{route[:source_location]}",
            insert_text: snippet,
            insert_text_format: 2 # Snippet format
          }
        end

        def build_route_helper_snippet(route)
          snippet = "#{route[:prefix]}_${1|path,url|}"

          # Build snippet with placeholders for params
          unless route[:params].empty?
            params_snippet = route[:params].map.with_index do |param, index|
              "${#{index + 2}:#{map_param_snippet(param, route[:controller])}}"
            end.join(", ")

            snippet += "(#{params_snippet})"
          end

          snippet
        end

        def map_param_snippet(param, controller)
          return param if param != "id"

          "@#{controller.split("/").last}"
        end

        def extract_current_controller(document_uri_path)
          # Extract controller name from path
          # Example: app/views/users/index.html.haml -> users
          # Example: app/controllers/users_controller.rb -> users
          return "" unless document_uri_path

          # Remove common Rails prefixes
          relative_path = document_uri_path.sub(%r{.*/app/(?:controllers|views)/}, "")

          # Extract controller name (first segment)
          parts = relative_path.split("/")
          controller = parts.first || ""

          # Remove _controller.rb suffix if present
          controller.sub(/_controller\.rb$/, "")
        end

        def match_score(path1, path2)
          # Calculate matching score based on path segments
          parts1 = path1.split("/")
          parts2 = path2.split("/")

          score = 0
          parts1.each_with_index do |part, index|
            break unless part == parts2[index]

            score += 1
          end

          score
        end
      end
    end
  end
end
