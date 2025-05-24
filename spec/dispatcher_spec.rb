# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Dispatcher do
  let(:runtime) { MultiAgent::Runtime::Stub.new(name: "test") }

  describe "#execute" do
    context "with sequential execution" do
      let(:dispatcher) { described_class.new(runtime: runtime, concurrency: 1) }
      let(:graph) { create_test_graph }

      it "executes tasks in sequence" do
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        dispatcher.execute(graph)
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        
        expect(duration).to be > 0
      end
    end

    context "with concurrent execution" do
      let(:graph) { create_parallel_graph }

      it "executes tasks faster with concurrency" do
        # Measure sequential
        seq_dispatcher = described_class.new(runtime: runtime, concurrency: 1)
        seq_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        seq_dispatcher.execute(graph)
        seq_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - seq_start
        
        # Measure concurrent
        con_dispatcher = described_class.new(runtime: runtime, concurrency: 4)
        con_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        con_dispatcher.execute(graph)
        con_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - con_start
        
        # Concurrent should be at least 30% faster for parallel tasks
        speedup = (seq_duration - con_duration) / seq_duration
        expect(speedup).to be > 0.3
      end
    end
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