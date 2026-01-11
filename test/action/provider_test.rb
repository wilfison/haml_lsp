# frozen_string_literal: true

require "test_helper"

class ActionProviderTest < Minitest::Test
  def setup
    @provider = HamlLsp::Action::Provider.new
  end

  def test_handle_request_with_html_conversion
    request = MockRequest.new(
      method: "textDocument/codeAction",
      document_uri: "file:///test.haml",
      params: {
        range: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 10 }
        }
      }
    )

    actions = @provider.handle_request(request, enable_lint: false)

    assert(actions.any? { |a| a[:title] == "Convert selected HTML/ERB to HAML" })
  end

  def test_handle_request_empty_selection
    request = MockRequest.new(
      method: "textDocument/codeAction",
      document_uri: "file:///test.haml",
      params: {}
    )

    actions = @provider.handle_request(request, enable_lint: false)

    assert_empty actions
  end

  def test_handle_resolve_returns_nil_with_nil_content
    document = Minitest::Mock.new
    document.expect(:content, nil)

    request = MockRequest.new(
      method: "codeAction/resolve",
      document_uri: "file:///test.haml",
      params: {
        kind: HamlLsp::Constant::CodeActionKind::REFACTOR
      }
    )

    result = @provider.handle_resolve(request, document, nil)

    assert_nil result
  end
end
