# frozen_string_literal: true

require "async"

module MultiAgent
  class Dispatcher
    def initialize(runtime:, concurrency: 1)
      @runtime = runtime
      @concurrency = concurrency
      @logger = SemanticLogger[self.class]
      @completed = Set.new
    end

    def execute(graph)
      @logger.info("Starting workflow execution", 
                   node_count: graph.nodes.size,
                   concurrency: @concurrency)
      
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      if @concurrency > 1
        execute_concurrent(graph)
      else
        execute_sequential(graph)
      end
      
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      @logger.info("Workflow execution complete", duration_s: duration.round(2))
    end

    private

    def execute_sequential(graph)
      while @completed.size < graph.nodes.size
        ready = graph.ready_nodes(@completed.to_a)
        break if ready.empty?
        
        ready.each do |node|
          execute_node(node)
          @completed << node.id
        end
      end
    end

    def execute_concurrent(graph)
      Async do |task|
        while @completed.size < graph.nodes.size
          ready = graph.ready_nodes(@completed.to_a)
          break if ready.empty?
          
          tasks = ready.map do |node|
            task.async do
              execute_node(node)
              @completed << node.id
            end
          end
          
          tasks.each(&:wait)
        end
      end
    end

    def execute_node(node)
      @logger.info("Executing node", node_id: node.id, node_type: node.type)
      
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      # Simulate node execution with runtime
      messages = [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: node.metadata["prompt"] || "Execute task: #{node.name}" }
      ]
      
      @runtime.lifecycle_start(node.name)
      @runtime.call(messages)
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      @runtime.lifecycle_end(node.name, (duration * 1000).round(2))
      
      @logger.info("Node execution complete", 
                   node_id: node.id, 
                   duration_s: duration.round(2))
    end
  end
end