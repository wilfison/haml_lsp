# frozen_string_literal: true

require "test_helper"

class HtmlToHamlTest < Minitest::Test
  def setup
    @action = HamlLsp::Action::HtmlToHaml
  end

  def test_action_items_with_empty_selection
    request = MockRequest.new(
      method: "textDocument/codeAction",
      document_uri: "file:///test.haml",
      params: {
        range: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 0 }
        }
      }
    )

    actions = @action.action_items(request)

    assert_empty actions
  end

  def test_action_items_with_valid_selection
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

    actions = @action.action_items(request)

    assert_equal 1, actions.size
    assert_equal "Convert selected HTML/ERB to HAML", actions[0][:title]
    assert_equal HamlLsp::Constant::CodeActionKind::REFACTOR, actions[0][:kind]
  end

  def test_action_items_without_range
    request = MockRequest.new(
      method: "textDocument/codeAction",
      document_uri: "file:///test.haml",
      params: {}
    )

    actions = @action.action_items(request)

    assert_empty actions
  end

  def test_action_resolver_single_line_conversion
    content = "<div class='test'>Hello</div>"
    document = Minitest::Mock.new
    document.expect(:content, content, [])
    document.expect(:content, content, [])

    request = MockRequest.new(
      method: "codeAction/resolve",
      document_uri: "file:///test.haml",
      params: {
        kind: HamlLsp::Constant::CodeActionKind::REFACTOR,
        range: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 29 }
        },
        data: {
          uri: "file:///test.haml",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 29 }
          }
        }
      }
    )

    result = @action.action_resolver_items(request, document)

    refute_nil result
    assert result.key?(:edit)
  end

  def test_action_resolver_multiline_conversion
    content = "<div>\n  <p>Hello</p>\n</div>"
    document = Minitest::Mock.new
    document.expect(:content, content, [])
    document.expect(:content, content, [])

    request = MockRequest.new(
      method: "codeAction/resolve",
      document_uri: "file:///test.haml",
      params: {
        kind: HamlLsp::Constant::CodeActionKind::REFACTOR,
        range: {
          start: { line: 0, character: 0 },
          end: { line: 2, character: 6 }
        },
        data: {
          uri: "file:///test.haml",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 2, character: 6 }
          }
        }
      }
    )

    result = @action.action_resolver_items(request, document)

    refute_nil result
    assert result.key?(:edit)
  end

  def test_action_resolver_with_erb
    content = "<%= link_to 'Home', root_path %>"
    document = Minitest::Mock.new
    document.expect(:content, content, [])
    document.expect(:content, content, [])

    request = MockRequest.new(
      method: "codeAction/resolve",
      document_uri: "file:///test.haml",
      params: {
        kind: HamlLsp::Constant::CodeActionKind::REFACTOR,
        range: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 34 }
        },
        data: {
          uri: "file:///test.haml",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 34 }
          }
        }
      }
    )

    result = @action.action_resolver_items(request, document)

    refute_nil result
    assert result.key?(:edit)
  end

  def test_action_resolver_nil_document
    request = MockRequest.new(
      method: "codeAction/resolve",
      document_uri: "file:///test.haml",
      params: {
        kind: HamlLsp::Constant::CodeActionKind::REFACTOR,
        range: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 10 }
        },
        data: {
          uri: "file:///test.haml",
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 10 }
          }
        }
      }
    )

    document = Minitest::Mock.new
    document.expect(:content, nil)

    result = @action.action_resolver_items(request, document)

    assert_nil result
  end
end
