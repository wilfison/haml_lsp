# frozen_string_literal: true

module HamlLsp
  module Message
    # A notification to be sent to the client or received from the client
    class Base
      attr_reader :method, :params

      def initialize(method:, params:)
        @method = method
        @params = params
      end

      def to_hash
        raise AbstractMethodInvokedError
      end
    end
  end
end
