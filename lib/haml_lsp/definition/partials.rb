# frozen_string_literal: true

module HamlLsp
  module Definition
    # Module to provide Rails partial definition lookups
    module Partials
      class << self
        PARTIAL_REGEXP = /render\s*\(?\s*(?:partial:)?\s*["']([^"']+)["']/

        # Find the definition location for a Rails partial
        # @param line [String] The current line content
        # @param document_uri_path [String] The current document file path
        # @param root_uri [String] The workspace root URI
        # @return [Array<HamlLsp::Interface::Location>] List of definition locations
        def find_definition(line, document_uri_path, root_uri)
          return [] if line.nil? || line.empty?
          return [] unless root_uri
          return [] unless line.match?(/=\s*render/)

          # Extract partial name from quotes
          partial_name = extract_partial_name(line)
          return [] if partial_name.nil? || partial_name.empty?

          # Find matching partial files
          partial_files = find_partial_files(partial_name, document_uri_path, root_uri)
          return [] if partial_files.empty?

          # Convert to LSP Location objects with scoring
          build_locations(partial_files)
        end

        private

        # Extract partial name from line
        # Handles: "users/profile", 'shared/header', users/profile
        # @param line [String] The current line content
        # @return [String, nil] Extracted partial name
        def extract_partial_name(line)
          # Remove surrounding quotes
          partial_name = line.match(PARTIAL_REGEXP)&.captures&.first
          return nil if partial_name.nil? || partial_name.empty?

          partial_name
        end

        # Find partial files matching the given name
        # @param partial_name [String] Partial name (e.g., "users/profile")
        # @param document_uri_path [String] Current document path
        # @param root_uri [String] Workspace root
        # @return [Array<Hash>] List of matching partial file info
        def find_partial_files(partial_name, document_uri_path, root_uri) # rubocop:disable Metrics/MethodLength
          views_path = File.join(root_uri, "app", "views")
          return [] unless Dir.exist?(views_path)

          current_dir = File.dirname(document_uri_path)

          candidates = []

          # Try multiple search strategies

          # 1. Exact match (with directory)
          if partial_name.include?("/")
            exact_file = find_exact_partial(partial_name, views_path)
            if exact_file
              candidates << {
                file: exact_file,
                score: calculate_score(exact_file, current_dir, strategy: :exact)
              }
            end
          end

          # 2. Search in current directory
          current_view_dir = extract_view_directory(document_uri_path, views_path)
          if current_view_dir
            local_file = find_in_directory(partial_name, current_view_dir)
            if local_file
              candidates << {
                file: local_file,
                score: calculate_score(local_file, current_dir, strategy: :local)
              }
            end
          end

          # 3. Search in shared directory
          shared_file = find_in_directory(partial_name, File.join(views_path, "shared"))
          if shared_file
            candidates << {
              file: shared_file,
              score: calculate_score(shared_file, current_dir, strategy: :shared)
            }
          end

          # 4. Search globally (all views directories)
          global_files = find_global_partials(partial_name, views_path)
          global_files.each do |file|
            candidates << {
              file: file,
              score: calculate_score(file, current_dir, strategy: :global)
            }
          end

          # Remove duplicates and sort by score (higher is better)
          candidates.uniq { |c| c[:file] }.sort_by { |c| -c[:score] }
        end

        # Find exact partial file path
        # @param partial_name [String] Partial name with directory (e.g., "users/profile")
        # @param views_path [String] Path to views directory
        # @return [String, nil] Full path to partial file
        def find_exact_partial(partial_name, views_path)
          dir, name = File.split(partial_name)
          partial_file = "_#{name}.html.haml"
          full_path = File.join(views_path, dir, partial_file)
          return full_path if File.exist?(full_path)

          partial_file = "_#{name}.haml"
          full_path = File.join(views_path, dir, partial_file)
          return full_path if File.exist?(full_path)

          nil
        end

        # Find partial in specific directory
        # @param partial_name [String] Partial name (without directory)
        # @param directory [String] Directory to search in
        # @return [String, nil] Full path to partial file
        def find_in_directory(partial_name, directory)
          return nil unless Dir.exist?(directory)

          # Remove directory prefix if present
          name = partial_name.split("/").last
          partial_file = "_#{name}.haml"
          full_path = File.join(directory, partial_file)

          File.exist?(full_path) ? full_path : nil
        end

        # Find all matching partials globally
        # @param partial_name [String] Partial name
        # @param views_path [String] Path to views directory
        # @return [Array<String>] List of matching partial files
        def find_global_partials(partial_name, views_path)
          name = partial_name.split("/").last
          pattern = "#{views_path}/**/_#{name}.haml"

          Dir.glob(pattern)
        end

        # Extract view directory from document path
        # @param document_uri_path [String] Current document path
        # @param views_path [String] Path to views directory
        # @return [String, nil] View directory path
        def extract_view_directory(document_uri_path, views_path)
          return nil unless document_uri_path.include?("app/views")

          # Get relative path from views directory
          if document_uri_path.start_with?(views_path)
            File.dirname(document_uri_path)
          else
            # Try to extract from path
            match = document_uri_path.match(%r{app/views/(.+?)/[^/]+$})
            match ? File.join(views_path, match[1]) : nil
          end
        end

        # Calculate score for a partial file
        # Higher score means better match
        # @param file [String] Partial file path
        # @param current_dir [String] Current document directory
        # @param strategy [Symbol] Search strategy used
        # @return [Integer] Score (higher is better)
        def calculate_score(file, current_dir, strategy:)
          base_score = case strategy
                       when :exact
                         1000 # Exact path match
                       when :local
                         800  # Same directory
                       when :shared
                         400  # Shared directory
                       when :global
                         200  # Global search
                       else
                         100
                       end

          # Add proximity bonus (inverse of distance)
          distance = calculate_distance(current_dir, File.dirname(file))
          proximity_bonus = [100 - (distance * 10), 0].max

          base_score + proximity_bonus
        end

        # Calculate distance between two paths
        # @param path1 [String] First path
        # @param path2 [String] Second path
        # @return [Integer] Number of directory levels between paths
        def calculate_distance(path1, path2)
          parts1 = path1.split("/")
          parts2 = path2.split("/")

          # Find common prefix length
          common_length = 0
          [parts1.length, parts2.length].min.times do |i|
            break if parts1[i] != parts2[i]

            common_length += 1
          end

          # Distance is the sum of remaining parts
          (parts1.length - common_length) + (parts2.length - common_length)
        end

        # Build LSP Location objects from partial files
        # @param partial_files [Array<Hash>] List of partial file info with scores
        # @return [Array<HamlLsp::Interface::Location>] List of locations
        def build_locations(partial_files)
          partial_files.map do |partial_info|
            HamlLsp::Interface::Location.new(
              uri: "file://#{partial_info[:file]}",
              range: HamlLsp::Interface::Range.new(
                start: HamlLsp::Interface::Position.new(line: 0, character: 0),
                end: HamlLsp::Interface::Position.new(line: 0, character: 0)
              )
            )
          end
        end
      end
    end
  end
end
