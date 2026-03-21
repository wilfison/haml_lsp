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
      LINE_REGEXP = /render\s*\(?\s*(?:partial:\s*)?(["'])/

      class << self
        # Handles completion requests for partials
        #
        # @param request [HamlLsp::Interface::Request] The LSP request object
        # @param line [String] The current line content
        # @param root_uri [String] The workspace root URI
        #
        # @return [Array<HamlLsp::Interface::CompletionItem>] List of completion items
        def completion_items(request, line, root_uri, partials_cache = nil)
          return [] unless root_uri

          match = line.match(LINE_REGEXP)
          return [] unless match

          current_path = request.document_uri_path
          cached = partials_cache && !partials_cache.empty? ? partials_cache : HamlLsp::Rails::PartialsScanner.scan(root_uri)
          partials = add_distance(cached, current_path)

          build_completion_items(
            partials, {
              position: request.params[:position],
              explicit: line.match?(/partial:\s*["']/),
              quote_char: match[1]
            }
          )
        end

        private

        def calculate_distance(path1, path2)
          HamlLsp::Utils.path_distance(path1, path2)
        end

        # Add per-request distance to cached partials
        def add_distance(cached_partials, document_uri_path)
          current_dir = File.dirname(document_uri_path)
          cached_partials.map do |partial|
            partial.merge(distance: calculate_distance(current_dir, File.dirname(partial[:file])))
          end
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
                start: { line: options[:position][:line].to_i, character: options[:position][:character].to_i - 1 },
                end: { line: options[:position][:line].to_i, character: options[:position][:character].to_i + 1 }
              },
              new_text: snippet
            },
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
          return "#{partial_path}, #{locals_snippet}" unless options[:explicit]

          "#{partial_path}, locals: { #{locals_snippet} }"
        end

        # Build locals snippet
        # @param locals [Array<Hash>] List of locals
        # @return [String] Snippet for locals hash
        def build_locals_snippet(locals)
          locals.map.with_index do |local, index|
            "${#{index + 1}:#{local[:name]}: #{local[:default]}}"
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
