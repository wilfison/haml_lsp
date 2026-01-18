# frozen_string_literal: true

module HamlLsp
  module Autocorrect
    # Handles autocorrection of lints
    class Base
      attr_reader :linter

      AUTOCORRECTABLE_LINTS_BY_ROW = {
        "TrailingWhitespace" => Autocorrect::TrailingWhitespace,
        "ClassesBeforeIds" => Autocorrect::ClassesBeforeIds,
        "SpaceBeforeScript" => Autocorrect::SpaceBeforeScript,
        "LeadingCommentSpace" => Autocorrect::LeadingCommentSpace,
        "HtmlAttributes" => Autocorrect::HtmlAttributes,
        "Indentation" => Autocorrect::Indentation
      }.freeze

      AUTOCORRECTABLE_LINTS_FULL_CONTENT = {
        "TrailingEmptyLines" => Autocorrect::TrailingEmptyLines,
        "FinalNewline" => Autocorrect::FinalNewline # needs to be last
      }.freeze

      class << self
        # Check if a diagnostic can be autocorrected
        # Only RuboCop lints support autocorrection
        def autocorrectable?(diagnostic)
          diagnostic[:source] == "rubocop"
        end

        def autocorrectable_diagnostics(diagnostics)
          diagnostics.select { |diag| diag[:source] == "rubocop" }
        end
      end

      def initialize(linter: nil)
        @linter = linter
      end

      # Autocorrect a specific file content
      def autocorrect(file_path, file_content)
        new_content = sanitize_content(file_content)
        new_content = fix_row_by_row(new_content)

        # Apply full content autocorrections
        AUTOCORRECTABLE_LINTS_FULL_CONTENT.each do |lint_name, autocorrector|
          next unless enabled_linter?(lint_name)

          config = config_for_linter(lint_name)
          new_content = autocorrector.autocorrect(new_content, config: config, config_linters: linter.config_linters)
        end

        Autocorrect::Rubocop.autocorrect(linter, file_path, new_content)
      end

      private

      def enabled_linter?(linter_name)
        linter.config_linters[linter_name]&.fetch("enabled", false)
      end

      def config_for_linter(linter_name)
        linter.config_linters[linter_name] || {}
      end

      def sanitize_content(file_content)
        file_content.to_s.strip.gsub("\t", "  ")
      end

      def fix_row_by_row(content)
        content_lines = content.lines.to_a
        inside_script_block = false
        last_script_indentation = nil

        # Apply line-by-line autocorrections
        content_lines.each_with_index do |line, index|
          line.rstrip!

          # Track whether we are inside a script block
          if line.strip.match?(/^:(\w+)$/)
            inside_script_block = true
            last_script_indentation = line[/^\s*/].to_s.length
          elsif inside_script_block
            current_indentation = line[/^\s*/].to_s.length
            if current_indentation <= last_script_indentation
              inside_script_block = false
              last_script_indentation = nil
            end
          end

          AUTOCORRECTABLE_LINTS_BY_ROW.each do |lint_name, autocorrector|
            next unless enabled_linter?(lint_name)

            config = config_for_linter(lint_name)
            line = autocorrector.autocorrect(line, config: config, config_linters: linter.config_linters)
          end

          content_lines[index] = line
        end

        content_lines.join("\n")
      end

      def calc_script_indentation(line)
        if line.strip.match?(/^:(\w+)$/)
          [true, line[/^\s*/].to_s.length]
        elsif inside_script_block
          current_indentation = line[/^\s*/].to_s.length
          [false, nil] if current_indentation <= last_script_indentation
        end
      end
    end
  end
end
