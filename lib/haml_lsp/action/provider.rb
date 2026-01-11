# frozen_string_literal: true

module HamlLsp
  module Action
    # Base class to handle actions requests
    class Provider
      def handle_request(request, enable_lint: true)
        actions = []
        actions += Action::Diagnostic.action_items(request) if enable_lint
        actions
      end

      def handle_resolve(request, document, autocorrector)
        return nil if document.content.nil?

        if request.params[:kind] == HamlLsp::Constant::CodeActionKind::QUICK_FIX
          Action::Diagnostic.action_resolver_items(request, document, autocorrector)
        else
          nil
        end
      end
    end
  end
end
