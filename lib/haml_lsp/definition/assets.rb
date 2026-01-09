# frozen_string_literal: true

module HamlLsp
  module Definition
    # Module to provide Rails asset definition lookups for JavaScript and CSS assets
    module Assets
      JAVASCRIPT_HELPERS = %w[javascript_include_tag javascript_pack_tag vite_javascript_tag].freeze
      STYLESHEET_HELPERS = %w[stylesheet_link_tag stylesheet_pack_tag vite_stylesheet_tag].freeze
      IMAGE_HELPERS = %w[asset_path image_path image_url image_tag].freeze

      JAVASCRIPT_ASSETS_PATHS = [
        "app/assets/javascripts",
        "app/javascript",
        "app/javascript/packs",
        "app/frontend",
        "app/frontend/javascripts",
        "public/javascripts",
        "public/assets",
        "vendor/assets/javascripts"
      ].freeze

      STYLESHEET_ASSETS_PATHS = [
        "app/assets/stylesheets",
        "app/javascript/stylesheets",
        "app/javascript/styles",
        "app/frontend",
        "app/frontend/stylesheets",
        "public/stylesheets",
        "public/assets",
        "vendor/assets/stylesheets"
      ].freeze

      IMAGE_ASSETS_PATHS = [
        "app/assets/images",
        "app/javascript/images",
        "public/images",
        "public/assets",
        "vendor/assets/images"
      ].freeze

      JAVASCRIPT_EXTENSIONS = %w[js coffee ts jsx tsx mjs es6].freeze
      STYLESHEET_EXTENSIONS = %w[css scss sass less stylus].freeze
      IMAGE_EXTENSIONS = %w[png jpg jpeg gif svg webp ico].freeze

      class << self
        # Find the definition location for a JavaScript or CSS asset
        # @param line [String] The current line content
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::Location>] List of definition locations
        def find_definition(line, root_uri)
          return [] if line.nil? || line.empty?
          return [] unless root_uri

          asset_context = extract_asset_context(line)
          return [] unless asset_context

          find_asset_file(asset_context[:helper], asset_context[:asset_name], root_uri)
        end

        private

        # Extract asset context from line
        # @param line [String] The current line content
        # @return [Hash, nil] Hash with :helper and :asset_name, or nil
        def extract_asset_context(line)
          all_helpers = JAVASCRIPT_HELPERS + STYLESHEET_HELPERS + IMAGE_HELPERS
          helpers_pattern = all_helpers.join("|")

          patterns = [
            /=\s*(#{helpers_pattern})\s*\(?\s*['"]([^'"]+)['"]/,
            /=\s*(#{helpers_pattern})\s*\(\s*['"]([^'"]+)['"]/,
            /\b(#{helpers_pattern})\s*\(?\s*['"]([^'"]+)['"]/
          ]

          patterns.each do |pattern|
            match = line.match(pattern)
            next unless match

            return {
              helper: match[1],
              asset_name: match[2]
            }
          end

          nil
        end

        # Find asset file locations
        # @param helper [String] The helper name (e.g., "javascript_include_tag")
        # @param asset_name [String] The asset name (e.g., "application", "users/profile")
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::Location>] List of locations
        def find_asset_file(helper, asset_name, root_uri)
          workspace_path = workspace_path_from_uri(root_uri)
          return [] unless workspace_path

          asset_directories = get_asset_directories(helper, workspace_path)
          extensions = get_asset_extensions(helper)
          ext_pattern = "{#{extensions.join(",")}}"

          locations = []

          asset_directories.each do |dir|
            next unless Dir.exist?(dir)

            file_path = if asset_name.match?(/\.[a-z0-9]+$/i)
                          # Asset name already includes extension
                          Dir.glob(File.join(dir, "**", asset_name)).first
                        elsif IMAGE_HELPERS.include?(helper)
                          # For images, try with any of the known extensions
                          Dir.glob(File.join(dir, "**", "#{asset_name}.#{ext_pattern}")).first
                        else
                          # For JS/CSS, try to find file with any of the known extensions
                          Dir.glob(File.join(dir, "#{asset_name}.#{ext_pattern}")).first
                        end

            locations << build_location(file_path) if file_path
          end

          locations
        end

        # Get asset directories based on helper type
        # @param helper [String] The helper name
        # @param workspace_path [String] The workspace root path
        # @return [Array<String>] List of directories to search
        def get_asset_directories(helper, workspace_path)
          paths = if JAVASCRIPT_HELPERS.include?(helper)
                    JAVASCRIPT_ASSETS_PATHS
                  elsif STYLESHEET_HELPERS.include?(helper)
                    STYLESHEET_ASSETS_PATHS
                  elsif IMAGE_HELPERS.include?(helper)
                    IMAGE_ASSETS_PATHS
                  else
                    []
                  end

          paths.map { |path| File.join(workspace_path, path) }
        end

        # Get asset extensions based on helper type
        # @param helper [String] The helper name
        # @return [Array<String>] List of file extensions
        def get_asset_extensions(helper)
          if JAVASCRIPT_HELPERS.include?(helper)
            JAVASCRIPT_EXTENSIONS
          elsif STYLESHEET_HELPERS.include?(helper)
            STYLESHEET_EXTENSIONS
          elsif IMAGE_HELPERS.include?(helper)
            IMAGE_EXTENSIONS
          else
            []
          end
        end

        # Build an LSP Location object for a file
        # @param file_path [String] Full path to the file
        # @return [HamlLsp::Interface::Location] LSP Location object
        def build_location(file_path)
          HamlLsp::Interface::Location.new(
            uri: "file://#{file_path}",
            range: HamlLsp::Interface::Range.new(
              start: HamlLsp::Interface::Position.new(line: 0, character: 0),
              end: HamlLsp::Interface::Position.new(line: 0, character: 0)
            )
          )
        end

        # Extract workspace path from URI
        # @param root_uri [String] The workspace root URI
        # @return [String, nil] Workspace path or nil
        def workspace_path_from_uri(root_uri)
          return nil unless root_uri

          # Remove file:// prefix if present
          path = root_uri.gsub(%r{^file://}, "")
          # URL decode the path
          URI.decode_www_form_component(path)
        rescue StandardError
          nil
        end
      end
    end
  end
end
