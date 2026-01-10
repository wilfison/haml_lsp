# frozen_string_literal: true

module HamlLsp
  module Completion
    # Module to provide Rails partial completions
    module Partials
      # Regexp to match render helper calls in the line
      # Matches:
      #   render('name')
      #   render "name"
      #   render(partial: "name")
      #   render partial: "name"
      LINE_REGEXP = /render\s*\(?\s*(?:partial:\s*)(["'])/

      class << self
        # Handles completion requests for partials
        #
        # @param document_uri_path [String] The current document file path
        # @param line [String] The current line content
        # @param root_uri [String] The workspace root URI
        #
        # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
        def completion_items(request, line, root_uri)
          return [] unless root_uri

          match = line.match?(LINE_REGEXP)
          return [] unless match

          partials = find_partials(request.document_uri_path, root_uri)

          build_completion_items(
            partials, {
              position: request.params[:position],
              explicit: line.match?(/partial:\s*["']/),
              quote_char: match[1]
            }
          )
        end

        private

        # Find all partial files in the views directory
        # @param document_uri_path [String] Current document path
        # @param root_uri [String] Workspace root
        # @return [Array<Hash>] List of partial info hashes
        def find_partials(document_uri_path, root_uri)
          views_path = File.join(root_uri, "app", "views")
          return [] unless Dir.exist?(views_path)

          current_dir = File.dirname(document_uri_path)

          partials = []
          Dir.glob("#{views_path}/**/_*.haml").each do |file|
            partial_info = extract_partial_info(file, views_path, current_dir)
            partials << partial_info if partial_info
          end

          partials
        end

        # Extract partial information from file
        # @param file [String] Full path to partial file
        # @param views_path [String] Path to views directory
        # @param current_dir [String] Current document directory
        # @return [Hash, nil] Partial info or nil
        def extract_partial_info(file, views_path, current_dir)
          # Get relative path from views directory
          relative_path = file.sub("#{views_path}/", "")

          # Extract directory and filename
          dir = File.dirname(relative_path)
          filename = File.basename(relative_path, ".haml")

          # Remove leading underscore from filename
          partial_name = filename.sub(/^_/, "")

          # Build full partial path
          full_partial_name = if dir == "."
                                partial_name
                              else
                                "#{dir}/#{partial_name}"
                              end

          # Extract locals from file
          locals = extract_locals(file)

          # Calculate distance score
          distance = calculate_distance(current_dir, File.dirname(file))

          {
            name: full_partial_name,
            file: file,
            locals: locals,
            distance: distance
          }
        end

        # Extract locals from partial file comments
        # Looks for: -# locals: (title:, body:, author: nil)
        # @param file [String] Path to partial file
        # @return [Array<Hash>] List of local variables
        def extract_locals(file)
          content = File.foreach(file).first(5).join("\n") # Read first 5 lines
          locals = []

          # Match -# locals: (var1:, var2: default_value)
          match = content.match(/^-#\s*locals:\s*\(([^)]+)\)/)
          return locals unless match

          params_string = match[1]
          params_string.split(",").each do |param|
            param = param.strip
            # Split by : to get name and default value
            parts = param.split(":", 2)
            var_name = parts[0].strip
            default_value = parts[1]&.strip

            locals << {
              name: var_name,
              default: default_value,
              required: default_value.nil? || default_value.empty?
            }
          end

          locals
        rescue StandardError => e
          HamlLsp.log("Error extracting locals from #{file}: #{e.message}")
          []
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

        # Build completion items from partials
        # @param partials [Array<Hash>] List of partial info
        # @param options [Hash] Options hash
        # @return [Array<Hash>] List of completion items
        def build_completion_items(partials, options = {})
          items = partials.map do |partial|
            build_completion_item(partial, options)
          end

          # Sort by distance (closer first) and mark closest as preselected
          items.sort_by! { |item| item[:sort_text] }
          items.first[:preselect] = true unless items.empty?

          items
        end

        # Build a single completion item for a partial
        # @param partial [Hash] Partial info
        # @param options [Hash] Options hash
        # @return [Hash] Completion item
        def build_completion_item(partial, options)
          snippet = build_partial_snippet(partial, options)
          detail = build_detail(partial)
          documentation = build_documentation(partial)

          # Use distance for sorting (lower distance = better)
          sort_text = format("%<distance>03d_%<name>s", distance: partial[:distance], name: partial[:name])

          {
            label: partial[:name],
            kind: Constant::CompletionItemKind::FILE,
            detail: detail,
            documentation: documentation,
            text_edit: {
              range: {
                start: options[:position][:character].to_i - 1,
                end: options[:position][:character].to_i + 1
              },
              new_text: snippet
            },
            # insert_text: snippet,
            # insert_text_format: 2, # Snippet format
            sort_text: sort_text
          }
        end

        # Build snippet for partial with locals
        # @param partial [Hash] Partial info
        # @param options [Hash] Options hash
        # @return [String] Snippet text
        def build_partial_snippet(partial, options)
          partial_name = partial[:name].sub(/(?:\.html)?\.haml$/, "")
          quote_char = options[:quote_char] || '"'
          partial_path = "#{quote_char}#{partial_name}#{quote_char}"

          return partial_path if partial[:locals].empty?

          locals_snippet = build_locals_snippet(partial[:locals])
          return "#{partial_path}, #{locals_snippet}" unless explicit

          "#{partial_path}, locals: { #{locals_snippet} }"
        end

        # Build locals snippet
        # @param locals [Array<Hash>] List of locals
        # @return [String] Snippet for locals hash
        def build_locals_snippet(locals)
          locals.map.with_index do |local, index|
            placeholder_index = index + 1
            if local[:required]
              "#{local[:name]}: ${#{placeholder_index}:value}"
            else
              "${#{placeholder_index}:#{local[:name]}: #{local[:default]}}"
            end
          end.join(", ")
        end

        # Build detail text
        # @param partial [Hash] Partial info
        # @return [String] Detail text
        def build_detail(partial)
          if partial[:locals].empty?
            "Partial (no locals)"
          else
            required = partial[:locals].count { |l| l[:required] }
            optional = partial[:locals].count { |l| !l[:required] }
            "Partial (#{required} required, #{optional} optional)"
          end
        end

        # Build documentation text
        # @param partial [Hash] Partial info
        # @return [String] Documentation text
        def build_documentation(partial)
          doc = "File: #{partial[:file]}"

          unless partial[:locals].empty?
            doc += "\n\nLocals:\n"
            partial[:locals].each do |local|
              status = local[:required] ? "required" : "optional (default: #{local[:default]})"
              doc += "- #{local[:name]}: #{status}\n"
            end
          end

          doc
        end
      end
    end
  end
end
