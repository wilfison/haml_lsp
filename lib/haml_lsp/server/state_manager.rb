# frozen_string_literal: true

module HamlLsp
  module Server
    # Manages server state (initialization, shutdown, etc)
    class StateManager
      attr_reader :initialized

      def initialize
        @initialized = false
      end

      def mark_initialized
        @initialized = true
      end

      def reset
        @initialized = false
      end
    end
  end
end
