# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection
    module LeadingCommentSpace
      REGEXP = /^(\s*)(-#)\s*(.*)$/

      # Separate comments from the leading '#' by a space.
      def self.autocorrect(line, _config = {}, _config_linters = {})
        line.sub(REGEXP, '\1-# \3')
      end
    end
  end
end
