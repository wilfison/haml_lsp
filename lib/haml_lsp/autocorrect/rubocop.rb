# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles RuboCop autocorrection using the linter
    module Rubocop
      def self.autocorrect(linter, file_path, file_content)
        linter.runner.format_document(
          file_content,
          file_path,
          reporter: linter.reporter
        )
      end
    end
  end
end
