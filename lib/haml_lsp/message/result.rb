# frozen_string_literal: true

module HamlLsp
  module Message
    # The final result of running a request before its IO is finalized
    class Result
      attr_reader :response, :id

      def initialize(id:, response:, error: nil)
        @id = id
        @response = response
        @error = error
      end

      def to_hash
        if @error
          { id: @id, error: @error }
        else
          { id: @id, result: @response }
        end
      end
    end
  end
end
