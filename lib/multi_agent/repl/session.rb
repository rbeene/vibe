# frozen_string_literal: true

require "async"
require "securerandom"
require "yaml"

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
        @conversation_history = {}

        if ir
          runtime_instance = create_runtime(runtime)
          @dispatcher = Dispatcher.new(runtime: runtime_instance, concurrency: concurrency)
          
          # Extract agent names and metadata from the IR graph
          ir.nodes.each do |node|
            @agents[node.id] = {
              name: node.name,
              runtime: runtime_instance,
              metadata: node.metadata || {},
              type: node.type
            }
            @conversation_history[node.id] = []
          end
          
          # Start dispatcher in async task
          @async_task = Async do
            @dispatcher.execute(ir)
          end
        end
      end

      # Dynamic loading inside REPL
      def load_agent(path)
        # Read the markdown file directly to get content
        content = File.read(path)
        
        # Parse frontmatter and body
        if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)/m
          frontmatter = YAML.load($1)
          body = $2
        else
          frontmatter = {}
          body = content
        end
        
        compiler = Markdown::Compiler.new
        ir_path = compiler.compile(path)
        ir = IR::Serializer.load(ir_path)
        
        node = ir.nodes.first
        runtime_instance = create_runtime(@runtime_name)
        
        @agents[node.id] = {
          name: node.name,
          runtime: runtime_instance,
          metadata: node.metadata || {},
          type: node.type,
          system_prompt: body.strip,
          config: frontmatter
        }
        
        @conversation_history[node.id] = []
        
        MultiAgent.logger.info("Loaded agent", agent: node.name, path: path)
      end

      def send_message(text, agent_name: nil, simple_mode: false, &block)
        if agent_name
          agent = @agents.values.find { |a| a[:name] == agent_name }
          raise "Unknown agent #{agent_name}" unless agent
          
          agent_id = @agents.key(agent)
          messages = build_messages(agent, text)
          response = agent[:runtime].call(messages)
          
          # Store assistant response in history
          @conversation_history[agent_id] << response
          
          @board << { agent: agent_name, message: text, response: response }
          response
        elsif simple_mode
          # Simple mode - all agents respond independently
          responses = {}
          @agents.each do |id, agent|
            messages = build_messages(agent, text)
            response = agent[:runtime].call(messages)
            
            # Store assistant response in history
            @conversation_history[id] << response
            
            responses[agent[:name]] = response
            @board << { agent: agent[:name], message: text, response: response }
          end
          responses
        else
          # Multi-agent conversation mode
          start_conversation(text, &block)
        end
      end

      def start_conversation(initial_message, &block)
        # Add user message to shared context
        shared_context = [{ role: "user", content: initial_message, name: "User" }]
        
        # Track which agents have responded
        responses = {}
        max_rounds = 5 # Prevent infinite loops
        round = 0
        
        while round < max_rounds
          round += 1
          any_responded = false
          
          @agents.each do |id, agent|
            # Check if agent has something to say
            if should_agent_respond?(agent, shared_context)
              messages = build_conversation_messages(agent, shared_context)
              
              MultiAgent.logger.debug("Conversation messages for #{agent[:name]}", 
                                     messages: messages, 
                                     should_respond: true)
              
              response = agent[:runtime].call(messages)
              
              if response[:content] && !response[:content].strip.empty?
                # Add agent's response to shared context
                shared_context << { 
                  role: "assistant", 
                  content: response[:content], 
                  name: agent[:name] 
                }
                
                responses[agent[:name]] = response
                any_responded = true
                
                # Store in conversation history
                @conversation_history[id] ||= []
                @conversation_history[id] << { role: "user", content: initial_message }
                @conversation_history[id] << response
                
                # Yield response for real-time display
                block.call(agent[:name], response) if block
              end
            end
          end
          
          # If no agent responded, conversation is done
          break unless any_responded
        end
        
        responses
      end

      def shutdown
        @async_task&.stop
      end

      private

      def build_messages(agent, text)
        agent_id = @agents.key(agent)
        messages = []
        
        # Add system prompt if available
        if agent[:system_prompt] && !agent[:system_prompt].empty?
          messages << { role: "system", content: agent[:system_prompt] }
        elsif agent[:metadata] && agent[:metadata]["prompt"]
          messages << { role: "system", content: agent[:metadata]["prompt"] }
        else
          messages << { role: "system", content: "You are #{agent[:name]}, a helpful assistant." }
        end
        
        # Add conversation history
        @conversation_history[agent_id]&.each do |msg|
          messages << msg
        end
        
        # Add current message
        messages << { role: "user", content: text }
        
        # Store in history
        @conversation_history[agent_id] ||= []
        @conversation_history[agent_id] << { role: "user", content: text }
        
        messages
      end

      def build_conversation_messages(agent, shared_context)
        messages = []
        
        # System prompt with multi-agent context
        system_prompt = agent[:system_prompt] || "You are #{agent[:name]}, a helpful assistant."
        system_prompt += "\n\nYou are in a conversation with: #{agent_names.join(', ')}. "
        system_prompt += "Respond naturally to the conversation. Keep responses concise."
        
        messages << { role: "system", content: system_prompt }
        
        # Add the shared conversation context
        shared_context.each do |msg|
          if msg[:name] && msg[:name] != agent[:name]
            # Format messages from other agents
            content = "[#{msg[:name]}]: #{msg[:content]}"
            messages << { role: msg[:role], content: content }
          else
            messages << { role: msg[:role], content: msg[:content] }
          end
        end
        
        # Add a prompt to encourage response
        if shared_context.length == 1
          messages << { role: "system", content: "Please provide your perspective on this topic." }
        end
        
        messages
      end

      def should_agent_respond?(agent, shared_context)
        # Don't respond if agent just spoke
        last_message = shared_context.last
        return false if last_message[:name] == agent[:name]
        
        # Always check on first round
        return true if shared_context.length == 1
        
        # Check if agent was mentioned
        recent_content = shared_context.last(3).map { |m| m[:content] }.join(" ")
        return true if recent_content.downcase.include?("@#{agent[:name]}")
        
        # Simple heuristic: agent hasn't responded in the last 2 messages
        recent_messages = shared_context.last(2)
        !recent_messages.any? { |msg| msg[:name] == agent[:name] }
      end

      def agent_names
        @agents.values.map { |a| a[:name] }
      end

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