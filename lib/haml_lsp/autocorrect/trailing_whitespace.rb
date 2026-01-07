# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection
    module TrailingWhitespace
      # HAML documents should not contain trailing whitespace (spaces or tabs) on any lines.
      def self.autocorrect(line, config: {}, config_linters: {})
        line.rstrip
      end
    end
  end
end
