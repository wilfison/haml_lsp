# frozen_string_literal: true

module HamlLsp
  # Handles autocorrection of lints
  class Autocorrector
    attr_reader :root_uri, :config_file

    def initialize(root_uri: nil, config_file: nil)
      @root_uri = root_uri
      @config_file = config_file
    end

    # Check if a diagnostic can be autocorrected
    # Only RuboCop lints support autocorrection
    def autocorrectable?(diagnostic)
      diagnostic[:source] == "rubocop"
    end

    def autocorrectable_diagnostics(diagnostics)
      diagnostics.select { |diag| diag[:source] == "rubocop" }
    end

    # Autocorrect a specific file content
    def autocorrect(file_path, file_content)
      sanitized_content = "#{file_content.strip.lines.map(&:chomp).join("\n")}\n"

      runner.format_document(
        sanitized_content,
        file_path,
        autocorrect: true,
        autocorrect_only: true,
        reporter: reporter
      )
    end

    private

    def runner
      @runner ||= HamlLsp::Lint::Runner.new
    end

    def reporter
      @reporter ||= HamlLint::Reporter::HashReporter.new(HamlLint::Logger.new($stderr))
    end
  end
end
