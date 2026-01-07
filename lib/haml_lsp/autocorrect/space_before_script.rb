# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection
    # Separate Ruby script indicators (-, =) from their code with a single space.
    module SpaceBeforeScript
      REGEXP = /^\s*([-=](?!#))(\s{0}|\s{2,})(\S+)/

      def self.autocorrect(line, _config = {}, _config_linters = {})
        if (match = line.match(REGEXP))
          line.sub("#{match[1]}#{match[2]}#{match[3]}", "#{match[1]} #{match[3]}")
        else
          line
        end
      end
    end
  end
end
