# frozen_string_literal: true

module HamlLsp
  # Manages server state (initialization, shutdown, etc)
  class ServerStateManager
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
