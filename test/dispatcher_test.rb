# frozen_string_literal: true

require "test_helper"

class DispatcherTest < Minitest::Test
  def setup
    super
    @runtime = MultiAgent::Runtime::Stub.new(name: "test")
  end

  def test_sequential_execution
    graph = create_test_graph
    dispatcher = MultiAgent::Dispatcher.new(runtime: @runtime, concurrency: 1)
    
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    dispatcher.execute(graph)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    
    # Sequential should take longer
    assert_operator duration, :>, 0
  end

  def test_concurrent_execution_speedup
    graph = create_parallel_graph
    
    # Measure sequential
    seq_dispatcher = MultiAgent::Dispatcher.new(runtime: @runtime, concurrency: 1)
    seq_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    seq_dispatcher.execute(graph)
    seq_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - seq_start
    
    # Measure concurrent
    con_dispatcher = MultiAgent::Dispatcher.new(runtime: @runtime, concurrency: 4)
    con_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    con_dispatcher.execute(graph)
    con_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - con_start
    
    # Concurrent should be at least 30% faster for parallel tasks
    speedup = (seq_duration - con_duration) / seq_duration
    assert_operator speedup, :>, 0.3, "Expected 30% speedup, got #{(speedup * 100).round}%"
  end

  private

  def create_test_graph
    nodes = [
      MultiAgent::IR::Node.new(id: "task1", type: "task", name: "Task 1"),
      MultiAgent::IR::Node.new(id: "task2", type: "task", name: "Task 2")
    ]
    
    edges = [
      MultiAgent::IR::Edge.new(id: "e1", source: "task1", target: "task2", type: "data")
    ]
    
    MultiAgent::IR::Graph.new(nodes: nodes, edges: edges)
  end

  def create_parallel_graph
    # Create 4 independent tasks that can run in parallel
    nodes = (1..4).map do |i|
      MultiAgent::IR::Node.new(id: "task#{i}", type: "task", name: "Task #{i}")
    end
    
    MultiAgent::IR::Graph.new(nodes: nodes, edges: [])
  end
end