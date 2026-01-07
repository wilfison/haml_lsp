# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection
    # HAML documents should not contain empty lines at the end of the file.
    module TrailingEmptyLines
      def self.autocorrect(content, _config = {}, _config_linters = {})
        content.rstrip
      end
    end
  end
end
