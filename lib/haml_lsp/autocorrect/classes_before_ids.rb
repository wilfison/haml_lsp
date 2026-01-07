# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection using the linter
    module ClassesBeforeIds
      REGEXP = /^(?:\s*)(#[\w-]+)(\.[\w-]+)|^(?:\s*)(\.[\w-]+)(#[\w-]+)/

      # Whether classes or ID attributes should be listed first in tags.
      def self.autocorrect(line, config: {}, config_linters: {})
        enforced_style = config.fetch("EnforcedStyle", "class")

        match = line.match(REGEXP)
        return line unless match

        id_attr = match[1] || match[4]
        class_attr = match[2] || match[3]
        sub_string = match.to_s.strip

        if enforced_style == "class"
          line.sub(sub_string, "#{class_attr}#{id_attr}")
        else
          line.sub(sub_string, "#{id_attr}#{class_attr}")
        end
      end
    end
  end
end
