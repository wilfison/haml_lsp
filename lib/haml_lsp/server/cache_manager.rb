# frozen_string_literal: true

module HamlLsp
  module Server
    # Manages caching of external resources like Rails routes and linter config
    class CacheManager
      def initialize(root_uri:, use_bundle: false)
        @root_uri = root_uri
        @use_bundle = use_bundle
        @rails_routes_cache = nil
        @partials_cache = nil
        @rails_project = nil
        @routes_loading_thread = nil
        @partials_loading_thread = nil
        @mutex = Mutex.new
      end

      def rails_routes
        @routes_loading_thread&.join

        @mutex.synchronize do
          load_rails_routes if @rails_project && @rails_routes_cache.nil?
          @rails_routes_cache || {}
        end
      end

      def load_rails_routes_async
        @routes_loading_thread = Thread.new do
          @mutex.synchronize { load_rails_routes }
        end
      end

      def partials
        @partials_loading_thread&.join

        @mutex.synchronize do
          load_partials if @partials_cache.nil?
          @partials_cache || []
        end
      end

      def load_partials_async
        @partials_loading_thread = Thread.new do
          @mutex.synchronize { load_partials }
        end
      end

      def rails_project?
        @rails_project ||= HamlLsp::Rails::Detector.rails_project?(@root_uri)
      end

      def invalidate_rails_routes
        @rails_routes_cache = nil
      end

      def invalidate_partials
        @partials_cache = nil
      end

      private

      def load_rails_routes
        raise "No root URI set" unless @root_uri

        @rails_routes_cache = HamlLsp::Rails::RoutesExtractor.extract_routes(@root_uri)
        HamlLsp.log("Loaded #{@rails_routes_cache.keys.size} Rails routes for autocompletion")
      rescue StandardError => e
        HamlLsp.log_error("Error extracting Rails routes")
        HamlLsp.log_error(e.message)
        @rails_routes_cache = {}
      end

      def load_partials
        @partials_cache = HamlLsp::Rails::PartialsScanner.scan(@root_uri)
        HamlLsp.log("Loaded #{@partials_cache.size} partials for autocompletion")
      rescue StandardError => e
        HamlLsp.log_error("Error scanning partials")
        HamlLsp.log_error(e.message)
        @partials_cache = []
      end
    end
  end
end
