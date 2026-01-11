# frozen_string_literal: true

require_relative "lib/haml_lsp/version"

Gem::Specification.new do |spec|
  spec.name = "haml_lsp"
  spec.version = HamlLsp::VERSION
  spec.authors = ["Wilfison"]
  spec.email = ["wilfisonbatista@gmail.com"]

  spec.summary = "Language Server Protocol implementation for HAML"
  spec.description = "A Ruby implementation of the Language Server Protocol (LSP) for HAML, providing features like autocomplete, diagnostics, and code navigation for HAML templates." # rubocop:disable Layout/LineLength
  spec.homepage = "https://github.com/wilfison/haml_lsp"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wilfison/haml_lsp"
  spec.metadata["changelog_uri"] = "https://github.com/wilfison/haml_lsp/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = ["haml_lsp"]
  spec.require_paths = ["lib"]

  spec.add_dependency "haml_lint", "~> 0.67"
  spec.add_dependency "html2haml", "~> 2.3"
  spec.add_dependency "language_server-protocol", "~> 3.17.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
