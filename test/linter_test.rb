# frozen_string_literal: true

require "test_helper"

class HamlLsp::LinterTest < Minitest::Test
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
    return if diagnostics.empty?

    diagnostic = diagnostics.first

    # Verifica que tem exatamente as chaves esperadas
    expected_keys = %i[range severity message codeDescription code source]
    assert_equal expected_keys.sort, diagnostic.keys.sort

    # Verifica a estrutura de range
    assert diagnostic.key?(:range)
    assert diagnostic[:range].key?(:start)
    assert diagnostic[:range].key?(:end)
    assert diagnostic[:range][:start].key?(:line)
    assert diagnostic[:range][:start].key?(:character)
    assert diagnostic[:range][:end].key?(:line)
    assert diagnostic[:range][:end].key?(:character)

    # Verifica os tipos
    assert_kind_of Integer, diagnostic[:severity]
    assert_kind_of String, diagnostic[:message]
    assert_kind_of String, diagnostic[:code]
    assert_kind_of String, diagnostic[:source]
    assert_nil diagnostic[:codeDescription]

    # Verifica que severity está entre 1 e 3 (Error, Warning, Info)
    assert_includes [1, 2, 3], diagnostic[:severity]

    # Verifica que source é haml_lint ou rubocop
    assert_includes %w[haml_lint rubocop], diagnostic[:source]
  end
end
