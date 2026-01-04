# frozen_string_literal: true

module HamlLsp
  module Completion
    # Base class to handle completion requests
    class Provider
      attr_reader :store, :rails_project

      def initialize(store:, rails_project:)
        @store = store
        @rails_project = rails_project
      end

      # Handles completion requests
      # @param request [HamlLsp::Message::Request] The completion request 'textDocument/completion'
      # @param rails_routes_cache [Array<Hash>] Cached Rails routes for autocompletion
      # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
      def handle(request, rails_routes_cache)
        document = store.get(request.document_uri)
        return [] unless document

        line = get_current_line(document, request)
        return [] unless line

        items = []
        items += HamlLsp::Completion::Routes.completion_items(request, line, rails_routes_cache) if rails_project?
        items += HamlLsp::Completion::Tags.completion_items(line)
        items += HamlLsp::Completion::Attributes.completion_items(line)
        items
      end

      private

      def rails_project?
        @rails_project
      end

      def get_current_line(document, request)
        # Extract line from document content at the current position
        position = request.params[:position]
        return nil unless position

        line_number = position[:line]
        character = position[:character]

        lines = document.content.split("\n")
        return nil if line_number >= lines.length

        # Get text from start of line to cursor position
        current_line = lines[line_number]
        current_line[0...character]
      end
    end
  end
end
