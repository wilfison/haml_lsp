# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Don't use the HTML-style attributes syntax to define attributes for an element.
    module HtmlAttributes
      REGEXP = /^\s*(?:[.#%][\w-]+)+\((.*)\)/
      REGEXP_ATTRS = /(\w[\w-]*)=(?:("[^"]*")|('[^']*')|([^"\s]*))/
      REGEX_VALUE = /"([^"]*)"|'([^']*)'/

      def self.autocorrect(line, config: {}, config_linters: {})
        match = line.match(REGEXP)
        return line unless line.match(REGEXP)

        attributes = parse_attributes(match[1])
        return line if attributes.empty?

        attributes_string = attributes.map { |attr| "#{attr[0]}: #{attr[1]}" }.join(", ")
        space = space_inside_hash_attributes(config_linters)

        if attributes_string.empty?
          line
        else
          line.sub("(#{match[1]})", "{#{space}#{attributes_string}#{space}}")
        end
      end

      def self.parse_attributes(attributes_string)
        result = []

        attributes_string.scan(REGEXP_ATTRS) do |key, double_quoted, single_quoted, unquoted|
          value = unquoted || fix_quotes(double_quoted || single_quoted)
          key_attr = key.include?("-") ? "'#{key}'" : key
          result << [key_attr, value]
        end

        result
      end

      def self.fix_quotes(value)
        match = value.match(REGEX_VALUE)
        match ? "'#{match[1] || match[2]}'" : value
      end

      def self.space_inside_hash_attributes(config_linters)
        linter_config = config_linters["SpaceInsideHashAttributes"] || {}
        return "" unless linter_config["enabled"]

        style = linter_config["style"] || "no_space"
        style == "space" ? " " : ""
      end
    end
  end
end
