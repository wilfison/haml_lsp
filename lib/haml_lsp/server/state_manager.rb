# frozen_string_literal: true

module HamlLsp
  module Server
    # Manages server state (initialization, shutdown, etc)
    class StateManager
      attr_reader :initialized

      def initialize
        @initialized = false
        @shutting_down = false
      end

      def mark_initialized
        @initialized = true
      end

      def mark_shutting_down
        @shutting_down = true
      end

      def shutting_down?
        @shutting_down
      end

      def reset
        @initialized = false
        @shutting_down = false
      end
    end
  end
end
