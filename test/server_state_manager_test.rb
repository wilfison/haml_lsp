# frozen_string_literal: true

require "test_helper"

class ServerStateManagerTest < Minitest::Test
  def test_initial_state_not_initialized
    state_manager = HamlLsp::ServerStateManager.new

    refute state_manager.initialized
  end

  def test_mark_initialized
    state_manager = HamlLsp::ServerStateManager.new
    state_manager.mark_initialized

    assert state_manager.initialized
  end

  def test_reset
    state_manager = HamlLsp::ServerStateManager.new
    state_manager.mark_initialized
    state_manager.reset

    refute state_manager.initialized
  end
end
