# frozen_string_literal: true

require "async"
require "securerandom"

module MultiAgent
  module Repl
    class Session
      attr_reader :trace_id, :board, :agents

      def initialize(ir: nil, runtime: "stub", concurrency: 4)
        @trace_id   = SecureRandom.uuid
        @board      = Blackboard.current(trace: @trace_id)
        @agents     = {}
        @dispatcher = nil
        @runtime_name = runtime
        @concurrency = concurrency

        if ir
          runtime_instance = create_runtime(runtime)
          @dispatcher = Dispatcher.new(runtime: runtime_instance, concurrency: concurrency)
          
          # Extract agent names from the IR graph
          ir.nodes.each do |node|
            @agents[node.id] = {
              name: node.name,
              runtime: runtime_instance
            }
          end
          
          # Start dispatcher in async task
          @async_task = Async do
            @dispatcher.execute(ir)
          end
        end
      end

      # Dynamic loading inside REPL
      def load_agent(path)
        compiler = Markdown::Compiler.new
        ir_path = compiler.compile(path)
        ir = IR::Serializer.load(ir_path)
        
        node = ir.nodes.first
        runtime_instance = create_runtime(@runtime_name)
        
        @agents[node.id] = {
          name: node.name,
          runtime: runtime_instance
        }
        
        MultiAgent.logger.info("Loaded agent", agent: node.name, path: path)
      end

      def send_message(text, agent_name: nil)
        if agent_name
          agent = @agents.values.find { |a| a[:name] == agent_name }
          raise "Unknown agent #{agent_name}" unless agent
          
          messages = [{ role: "user", content: text }]
          response = agent[:runtime].call(messages)
          
          @board << { agent: agent_name, message: text, response: response }
          response
        else
          # Send to all agents
          responses = {}
          @agents.each do |id, agent|
            messages = [{ role: "user", content: text }]
            response = agent[:runtime].call(messages)
            responses[agent[:name]] = response
            @board << { agent: agent[:name], message: text, response: response }
          end
          responses
        end
      end

      def shutdown
        @async_task&.stop
      end

      private

      def create_runtime(runtime_name)
        case runtime_name
        when "stub"
          Runtime::Stub.new(name: "repl-#{@trace_id}")
        when "openai"
          Runtime::OpenaiAdapter.new(name: "repl-#{@trace_id}")
        else
          raise "Unknown runtime: #{runtime_name}"
        end
      end
    end
  end
end