# frozen_string_literal: true

module HamlLsp
  module Definition
    # Base provider class for definitions
    class Provider
      attr_reader :store, :rails_project

      def initialize(store:, rails_project:)
        @store = store
        @rails_project = rails_project
      end

      # Handles completion requests
      # @param request [HamlLsp::Message::Request] The completion request 'textDocument/completion'
      # @param rails_routes_cache [Array<Hash>] Cached Rails routes for autocompletion
      # @param root_uri [String] The workspace root URI
      # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
      def handle(request, rails_routes_cache, root_uri = nil)
        document = store.get(request.document_uri)
        return [] unless document

        line_index = request.params.dig(:position, :line).to_i
        character_index = request.params.dig(:position, :character).to_i

        line = document.line_at_position(line_index)
        word = document.word_at_position(line_index, character_index)
        return [] unless line && word

        locations = []
        # Try partials definition first (works for both Rails and non-Rails projects)
        locations += partial_locations(line, request.document_uri_path, root_uri) if root_uri

        if rails_project?
          # Try Rails routes definition if Rails project
          locations += route_locations(word, rails_routes_cache, root_uri)
          # Try assets definition (JavaScript, CSS and images)
          locations += asset_locations(line, root_uri) if root_uri
        end

        locations
      end

      private

      def rails_project?
        @rails_project
      end

      def get_current_line(document, request)
        # Extract line from document content at the current position
        position = request.params[:position]
        return nil unless position

        document.word_at_position(position[:line])
      end

      def partial_locations(line, document_uri_path, root_uri)
        HamlLsp::Definition::Partials.find_definition(
          line,
          document_uri_path,
          root_uri
        )
      end

      def route_locations(word, rails_routes_cache, root_uri)
        return [] unless rails_project? && rails_routes_cache && !rails_routes_cache.empty?

        HamlLsp::Definition::Routes.find_definition(word, rails_routes_cache, root_uri)
      end

      def asset_locations(line, root_uri)
        HamlLsp::Definition::Assets.find_definition(line, root_uri)
      end
    end
  end
end
