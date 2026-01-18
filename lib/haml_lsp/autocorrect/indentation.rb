# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection using the linter
    module Indentation
      REGEXP = /\A[ \t]*/

      # Check that spaces are used for indentation instead of hard tabs.
      def self.autocorrect(line, config: {}, config_linters: {})
        leading_spaces = line[REGEXP]
        return line if leading_spaces.nil? || leading_spaces.empty?

        character = config.fetch("character", "space") == "space" ? " " : "\t"
        width = config.fetch("width", 2)
        indent_unit = character * width

        # Calculate the number of indent units
        indent_level = leading_spaces.gsub("\t", " " * width).size / width
        new_leading = indent_unit * indent_level
        line.sub(REGEXP, new_leading)
      end
    end
  end
end
