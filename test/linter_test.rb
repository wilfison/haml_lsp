# frozen_string_literal: true

require "test_helper"

module HamlLsp
  class LinterTest < Minitest::Test
    def setup
      @linter = HamlLsp::Linter.new(root_uri: nil)
    end

    def test_linter_initialization
      refute_nil @linter
      assert_instance_of HamlLsp::Linter, @linter
    end

    def test_lint_file_with_valid_haml
      file_path = "/tmp/test.haml"
      file_content = "%h1 Hello World\n%p This is valid HAML\n"

      diagnostics = @linter.lint_file(file_path, file_content)

      assert_instance_of Array, diagnostics
    end

    def test_lint_file_with_invalid_haml
      file_path = "/tmp/test.haml"
      # Invalid HAML: improper indentation
      file_content = "%h1 Hello\n    %p This is bad indentation\n"

      diagnostics = @linter.lint_file(file_path, file_content)

      assert_instance_of Array, diagnostics
    end

    def test_config_file_is_optional
      assert_nil @linter.config_file
    end

    def test_diagnostic_hash_structure
      file_path = "/tmp/test.haml"
      # HAML com possíveis problemas de lint
      file_content = "%h1 Hello\n    %p This is bad indentation\n"

      diagnostics = @linter.lint_file(file_path, file_content)

      # Se houver diagnósticos, testa a estrutura
      skip if diagnostics.empty?

      diagnostic = diagnostics.first

      # Verifica que é um objeto Diagnostic do LSP
      assert_instance_of LanguageServer::Protocol::Interface::Diagnostic, diagnostic

      # Verifica as propriedades do diagnostic
      assert_instance_of LanguageServer::Protocol::Interface::Range, diagnostic.attributes[:range]
      assert_instance_of Integer, diagnostic.attributes[:severity]
      assert_instance_of String, diagnostic.attributes[:message]
      assert_instance_of String, diagnostic.attributes[:code]
      assert_instance_of String, diagnostic.attributes[:source]

      # Verifica a estrutura de range
      range = diagnostic.attributes[:range]

      assert_instance_of LanguageServer::Protocol::Interface::Position, range.attributes[:start]
      assert_instance_of LanguageServer::Protocol::Interface::Position, range.attributes[:end]

      # Verifica que severity está entre 1 e 3 (Error, Warning, Info)
      assert_includes [1, 2, 3], diagnostic.attributes[:severity]

      # Verifica que source é haml_lint ou rubocop
      assert_includes %w[haml_lint rubocop], diagnostic.attributes[:source]
    end

    def test_find_config_file_with_root_uri
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".haml-lint.yml")
        File.write(config_path, "linters:\n  LineLength:\n    enabled: false\n")

        linter = HamlLsp::Linter.new(root_uri: dir)

        assert_equal config_path, linter.config_file
      end
    end

    def test_find_config_file_with_spaces_in_path
      Dir.mktmpdir("path with spaces") do |dir|
        config_path = File.join(dir, ".haml-lint.yml")
        File.write(config_path, "linters:\n  LineLength:\n    enabled: false\n")

        linter = HamlLsp::Linter.new(root_uri: dir)

        assert_equal config_path, linter.config_file
      end
    end
  end
end
