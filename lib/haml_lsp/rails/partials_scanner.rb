# frozen_string_literal: true

module HamlLsp
  module Rails
    # Scans the views directory for partial files and extracts metadata
    module PartialsScanner
      class << self
        # Scan all partial files under app/views
        # @param root_uri [String] The workspace root path
        # @return [Array<Hash>] List of partial info hashes (without distance)
        def scan(root_uri)
          return [] unless root_uri

          views_path = File.join(root_uri, "app", "views")
          return [] unless Dir.exist?(views_path)

          Dir.glob("#{views_path}/**/_*.haml").filter_map do |file|
            extract_partial_info(file, views_path)
          end
        end

        private

        def extract_partial_info(file, views_path)
          relative_path = file.sub("#{views_path}/", "")
          dir = File.dirname(relative_path)
          filename = File.basename(relative_path, ".haml")
          partial_name = filename.sub(/^_/, "")

          full_partial_name = dir == "." ? partial_name : "#{dir}/#{partial_name}"

          {
            name: full_partial_name,
            file: file,
            locals: extract_locals(file)
          }
        end

        # Extract locals from partial file comments
        # Looks for: -# locals: (title:, body:, author: nil)
        def extract_locals(file)
          content = File.foreach(file).first(5).join("\n")
          match = content.match(/^-#\s*locals:\s*\(([^)]+)\)/)
          return [] unless match

          match[1].split(",").map do |param|
            parts = param.strip.split(":", 2)
            var_name = parts[0].strip
            default_value = parts[1]&.strip

            {
              name: var_name,
              default: default_value,
              required: default_value.nil? || default_value.empty?
            }
          end
        rescue StandardError => e
          HamlLsp.log("Error extracting locals from #{file}: #{e.message}")
          []
        end
      end
    end
  end
end
