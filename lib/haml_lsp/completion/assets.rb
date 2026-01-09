# frozen_string_literal: true

module HamlLsp
  module Completion
    # Module to provide Rails asset helpers completions
    module Assets
      JAVASCRIPT_HELPERS = %w[javascript_include_tag javascript_pack_tag vite_javascript_tag].freeze
      STYLESHEET_HELPERS = %w[stylesheet_link_tag stylesheet_pack_tag vite_stylesheet_tag].freeze
      IMAGE_HELPERS = %w[asset_path image_path image_url image_tag].freeze
      VIDEO_HELPERS = %w[video_tag video_path video_url].freeze
      AUDIO_HELPERS = %w[audio_tag audio_path audio_url].freeze

      ASSET_HELPERS = (
        ["asset_path"] +
        IMAGE_HELPERS +
        JAVASCRIPT_HELPERS +
        STYLESHEET_HELPERS +
        VIDEO_HELPERS +
        AUDIO_HELPERS
      ).freeze

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

      AUDIO_ASSETS_PATHS = [
        "app/assets/audios",
        "public/audios",
        "public/assets"
      ].freeze

      VIDEO_ASSETS_PATHS = [
        "app/assets/videos",
        "public/videos",
        "public/assets"
      ].freeze

      IMAGE_EXTENSIONS = %w[png jpg jpeg gif svg webp ico].freeze
      JAVASCRIPT_EXTENSIONS = %w[js coffee ts jsx tsx mjs es6].freeze
      STYLESHEET_EXTENSIONS = %w[css scss sass less stylus].freeze
      AUDIO_EXTENSIONS = %w[mp3 wav ogg m4a].freeze
      VIDEO_EXTENSIONS = %w[mp4 webm ogv avi].freeze

      ALL_EXTENSIONS = (
        IMAGE_EXTENSIONS +
        JAVASCRIPT_EXTENSIONS +
        STYLESHEET_EXTENSIONS +
        AUDIO_EXTENSIONS +
        VIDEO_EXTENSIONS
      ).freeze

      class << self
        # Handles completion requests for asset helpers
        # @param line [String] The current line content
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
        def completion_items(line, root_uri)
          return [] unless root_uri

          asset_context = get_asset_context(line)
          return [] unless asset_context

          get_asset_completions(asset_context[:helper], asset_context[:prefix], root_uri)
        end

        private

        def get_asset_context(line)
          helpers = ASSET_HELPERS.join("|")
          patterns = [
            /=\s*(#{helpers})\s*\(?\s*['"]([^'"]*)/,
            /=\s*(#{helpers})\s*\(?\s*([^'"][^,)\s]*)/,
            /=\s*(#{helpers})\s*\(\s*['"]([^'"]*)/,
            /\b(#{helpers})\s*\(?\s*['"]([^'"]*)/
          ]

          patterns.map do |pattern|
            match = line.match(pattern)
            next unless match

            { helper: match[1], prefix: match[2] || "" }
          end.compact.first
        end

        def get_asset_completions(helper, prefix, root_uri)
          workspace_path = workspace_path_from_uri(root_uri)
          return [] unless workspace_path

          deep_search = !(JAVASCRIPT_HELPERS + STYLESHEET_HELPERS).include?(helper)
          asset_paths = get_asset_paths(helper, workspace_path, deep_search)
          completions = []

          asset_paths.each do |asset_path|
            asset_name = get_asset_name(helper, asset_path)

            next unless asset_name.start_with?(prefix)

            completions << {
              label: asset_path,
              kind: Constant::CompletionItemKind::FILE,
              detail: get_asset_detail(helper, asset_path),
              documentation: "**File:** `#{asset_path}`",
              insert_text: asset_name,
              sort_text: asset_path
            }
          end

          completions
        end

        def get_asset_name(helper, asset_path)
          if helper.include?("javascript") || helper.include?("stylesheet") || helper.include?("vite")
            File.basename(asset_path, File.extname(asset_path))
          else
            asset_path
          end
        end

        def get_asset_paths(helper, workspace_path, deep_search)
          asset_directories = get_asset_directories(helper, workspace_path)
          assets = []

          asset_directories.each do |dir|
            assets.concat(scan_directory(dir, get_asset_extensions(helper), deep_search)) if Dir.exist?(dir)
          end

          assets.uniq
        end

        def respond_to_image_helper?(helper)
          helper == "asset_path" || helper.include?("image")
        end

        def respond_to_javascript_helper?(helper)
          helper == "asset_path" || JAVASCRIPT_HELPERS.include?(helper)
        end

        def respond_to_stylesheet_helper?(helper)
          helper == "asset_path" || STYLESHEET_HELPERS.include?(helper)
        end

        def respond_to_audio_helper?(helper)
          helper == "asset_path" || helper.include?("audio")
        end

        def respond_to_video_helper?(helper)
          helper == "asset_path" || VIDEO_HELPERS.include?(helper)
        end

        def get_asset_directories(helper, workspace_path)
          directories = []
          directories += IMAGE_ASSETS_PATHS if respond_to_image_helper?(helper)
          directories += JAVASCRIPT_ASSETS_PATHS if respond_to_javascript_helper?(helper)
          directories += STYLESHEET_ASSETS_PATHS if respond_to_stylesheet_helper?(helper)
          directories += AUDIO_ASSETS_PATHS if respond_to_audio_helper?(helper)
          directories += VIDEO_ASSETS_PATHS if respond_to_video_helper?(helper)

          directories.uniq.map { |dir| File.join(workspace_path, dir) }
        end

        def get_asset_extensions(helper)
          if helper == "asset_path"
            ALL_EXTENSIONS
          elsif respond_to_image_helper?(helper)
            IMAGE_EXTENSIONS
          elsif respond_to_javascript_helper?(helper)
            JAVASCRIPT_EXTENSIONS
          elsif respond_to_stylesheet_helper?(helper)
            STYLESHEET_EXTENSIONS
          elsif respond_to_audio_helper?(helper)
            AUDIO_EXTENSIONS
          elsif respond_to_video_helper?(helper)
            VIDEO_EXTENSIONS
          else
            []
          end
        end

        def scan_directory(directory, extensions, deep_search)
          deep_pattern = deep_search ? "**" : ""
          ext_pattern = "*.{#{extensions.join(",")}}"

          Dir.glob(File.join(directory, deep_pattern, ext_pattern)).map do |file_path|
            file_path.sub("#{directory}/", "")
          end
        end

        def get_asset_detail(helper, asset_path)
          if helper.include?("image")
            "Image asset: #{asset_path}"
          elsif helper.include?("javascript") || helper.include?("vite_javascript")
            "JavaScript asset: #{asset_path}"
          elsif helper.include?("stylesheet") || helper.include?("vite_stylesheet")
            "Stylesheet asset: #{asset_path}"
          elsif helper.include?("audio")
            "Audio asset: #{asset_path}"
          elsif helper.include?("video")
            "Video asset: #{asset_path}"
          elsif helper.include?("vite")
            "Vite asset: #{asset_path}"
          else
            "Asset: #{asset_path}"
          end
        end

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
