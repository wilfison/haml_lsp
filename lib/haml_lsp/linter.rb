# frozen_string_literal: true

module HamlLsp
  # Linter class to run haml-lint and parse results
  class Linter
    attr_reader :root_uri, :config_file

    def initialize(root_uri: false)
      @root_uri = root_uri

      find_config_file
    end

    def lint_file(file_path, file_content)
      report = runner.run(
        file_content,
        file_path,
        config_file: config_file,
        reporter: reporter
      )

      parse_lint_reports(report.lints, file_content)
    end

    private

    def runner
      @runner ||= HamlLsp::Lint::Runner.new
    end

    def reporter
      @reporter ||= HamlLint::Reporter::HashReporter.new(HamlLint::Logger.new($stderr))
    end

    def find_config_file
      possible_paths = []

      if root_uri
        root_path = URI.parse(root_uri).path
        possible_paths << File.join(root_path, ".haml-lint.yml")
        possible_paths << File.join(root_path, "config", "haml-lint.yml")
      end

      possible_paths << File.join(Dir.pwd, ".haml-lint.yml")
      possible_paths << File.join(Dir.pwd, "config", "haml-lint.yml")

      @config_file = possible_paths.find { |path| File.exist?(path) }
    end

    def parse_lint_reports(reports, file_content)
      return [] if reports.empty?

      reports.map do |report|
        range = report_range_for_line(file_content, report.line - 1)

        HamlLsp::Interface::Diagnostic.new(
          range: range,
          severity: map_severity(report.severity.to_s),
          message: report.message,
          code: map_rule_name(report),
          source: report.linter.name == "RuboCop" ? "rubocop" : "haml_lint"
        )
      end
    end

    def map_severity(severity)
      case severity
      when "warning"
        HamlLsp::Constant::DiagnosticSeverity::WARNING
      when "error", "fatal"
        HamlLsp::Constant::DiagnosticSeverity::ERROR
      else
        HamlLsp::Constant::DiagnosticSeverity::INFORMATION
      end
    end

    def map_rule_name(report)
      return report.linter.name unless report.linter.name == "RuboCop"

      matches = report.message.match(%r{^([\w/]*):\s(.*)})
      matches ? matches[1] : report.linter.name
    end

    def report_range_for_line(content, line_number)
      line = content.to_s.lines[line_number].to_s
      sanitized_line = line.chomp

      HamlLsp::Interface::Range.new(
        start: HamlLsp::Interface::Position.new(
          line: line_number,
          character: first_non_empty_line_character(sanitized_line)
        ),
        end: HamlLsp::Interface::Position.new(
          line: line_number,
          character: sanitized_line.empty? ? line.length : sanitized_line.length
        )
      )
    end

    def first_non_empty_line_character(line)
      line.index(/[^ \t]/) || line.length
    end
  end
end
