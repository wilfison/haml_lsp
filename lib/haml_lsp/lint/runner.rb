# frozen_string_literal: true

module HamlLsp
  module Lint
    # Runner class to run haml-lint with in-memory documents
    class Runner < HamlLint::Runner
      attr_accessor :document

      # @override HamlLint::Runner#run
      def run(template, file_path, options = {})
        @config = load_applicable_config(options)
        @sources = extract_sources(template, file_path)
        @linter_selector = HamlLint::LinterSelector.new(config, options)
        @fail_fast = options.fetch(:fail_fast, false)
        @cache = {}
        @autocorrect = options[:autocorrect]
        @autocorrect_only = options[:autocorrect_only]
        @autocorrect_stdout = options[:stdin] && options[:stderr]

        report(options)
      end

      def format_document(template, file_path, options = {})
        @config = load_applicable_config(options)
        @source = extract_sources(template, file_path).first

        autocorrect_template(@source, @config)
      end

      private

      # override to use in-memory source
      def extract_sources(template, file_path)
        [HamlLint::Source.new(io: StringIO.new(template), path: file_path)]
      end

      # Simplify autocorrect to work with in-memory documents
      def autocorrect_template(source, config)
        begin
          document = HamlLint::Document.new(
            source.contents,
            file: source.path,
            config: config,
            file_on_disk: false,
            write_to_stdout: false
          )
        rescue HamlLint::Exceptions::ParseError
          return source.contents
        end

        document.send(:unstrip_frontmatter, document.source)
      end

      # @override to use in-memory document
      def autocorrect_document(document, linters)
        lint_arrays = []

        autocorrecting_linters = linters.select(&:supports_autocorrect?)
        lint_arrays << autocorrecting_linters.map do |linter|
          linter.run(document, autocorrect: @autocorrect)
        end

        # override to prevent file writing on disk when autocorrecting
        # Instead, we will just set the document to the autocorrected version
        self.document = document

        lint_arrays
      end
    end
  end
end
