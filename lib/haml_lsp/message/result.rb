# frozen_string_literal: true

module HamlLsp
  module Message
    # The final result of running a request before its IO is finalized
    class Result
      attr_reader :response, :id

      def initialize(id:, response:)
        @id = id
        @response = response
      end

      def to_hash
        { id: @id, result: @response }
      end
    end
  end
end
