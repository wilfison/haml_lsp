# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection using the linter
    module FinalNewline
      # Files should always have a final newline. This results in better diffs
      # when adding lines to the file, since SCM systems such as git won't think
      # that you touched the last line if you append to the end of a file.
      def self.autocorrect(content, config: {}, config_linters: {})
        if config["present"] == true
          ensure_final_newline(content)
        else
          content.rstrip
        end
      end

      def self.ensure_final_newline(content)
        "#{content.rstrip}\n"
      end
    end
  end
end
