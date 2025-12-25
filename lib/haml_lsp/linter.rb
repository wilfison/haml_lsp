# frozen_string_literal: true

# Linter class to run haml-lint and parse results
class HamlLsp::Linter
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

    parse_lint_reports(report.lints)
  end

  private

  def runner
    @runner ||= HamlLsp::Linter::Runner.new
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

  def parse_lint_reports(reports)
    return [] if reports.empty?

    reports.map do |report|
      {
        range: {
          start: { line: report.line - 1, character: 0 },
          end: { line: report.line - 1, character: 0 }
        },
        severity: map_severity(report.severity.to_s),
        message: report.message,
        codeDescription: nil,
        code: report.linter.name,
        source: report.linter.name == "RuboCop" ? "rubocop" : "haml_lint"
      }
    end
  end

  def map_severity(severity)
    case severity
    when "warning"
      2 # Warning
    when "error", "fatal"
      1 # Error
    else
      3 # Default to Information
    end
  end
end
