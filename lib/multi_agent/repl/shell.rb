# frozen_string_literal: true

require "readline"

module MultiAgent
  module Repl
    class Shell
      PROMPT = -> { "ma> " }

      def initialize(session)
        @session = session
        @conversation_mode = false
      end

      def start
        puts "Multi-Agent REPL – trace #{@session.trace_id}"
        puts "Type /help for commands"
        
        while (line = Readline.readline(PROMPT.call, true))
          line = line.strip
          next if line.empty?
          
          begin
            case line
            when %r{^/exit}
              break
            when %r{^/help}
              show_help
            when %r{^/board}
              show_board
            when %r{^/mem (\S+)}
              show_memory($1)
            when %r{^/reload (.+)}
              reload_agent($1)
            when %r{^/agents}
              show_agents
            when %r{^/conv}
              toggle_conversation_mode
            when %r{^@(\S+):\s+(.+)}
              send_to_agent($1, $2)
            else
              if @conversation_mode
                send_to_all(line)
              else
                send_to_all_simple(line)
              end
            end
          rescue StandardError => e
            puts "Error: #{e.message}"
            MultiAgent.logger.error("REPL error", error: e.message, backtrace: e.backtrace)
          end
        end
      ensure
        puts "\nShutting down..."
        @session.shutdown
        puts "bye!"
      end

      private

      def show_help
        puts <<~HELP
          Commands:
            /help          - Show this help
            /exit          - Exit REPL
            /board         - Show blackboard entries
            /mem <agent>   - Show memory for agent
            /reload <path> - Load/reload agent from file
            /agents        - List loaded agents
            /conv          - Toggle conversation mode (agents talk to each other)
            @<agent>: msg  - Send message to specific agent
            <message>      - Send message to all agents
            
          Conversation mode: #{@conversation_mode ? 'ON' : 'OFF'}
        HELP
      end

      def show_board
        entries = @session.board.entries
        if entries.empty?
          puts "Blackboard is empty"
        else
          puts "Blackboard entries (#{entries.size}):"
          entries.last(10).each_with_index do |entry, i|
            puts "  [#{i}] #{entry[:ts]&.strftime('%H:%M:%S') || 'N/A'}: #{entry[:data].inspect}"
          end
        end
      end

      def show_memory(agent_name)
        if @session.agents.any? { |_, a| a[:name] == agent_name }
          memory = MemoryView.for(agent_name, trace: @session.trace_id)
          puts "Memory for #{agent_name}:"
          if memory.respond_to?(:to_a)
            memory.to_a.each { |item| puts "  #{item}" }
          else
            puts "  (no memory view available)"
          end
        else
          puts "Unknown agent: #{agent_name}"
        end
      end

      def reload_agent(path)
        @session.load_agent(path)
        puts "Loaded agent from #{path}"
      end

      def show_agents
        if @session.agents.empty?
          puts "No agents loaded"
        else
          puts "Loaded agents:"
          @session.agents.each do |id, agent|
            puts "  - #{agent[:name]} (#{id})"
          end
        end
      end

      def send_to_agent(agent_name, message)
        response = @session.send_message(message, agent_name: agent_name)
        puts "#{agent_name}: #{response[:content] || '(no response)'}"
        
        if response[:tool_calls]
          puts "  Tool calls: #{response[:tool_calls].map { |tc| tc[:function][:name] }.join(', ')}"
        end
      end

      def toggle_conversation_mode
        @conversation_mode = !@conversation_mode
        puts "Conversation mode: #{@conversation_mode ? 'ON' : 'OFF'}"
        if @conversation_mode
          puts "Agents will now respond to each other in a natural conversation."
        else
          puts "Agents will respond individually without interacting."
        end
      end

      def send_to_all(message)
        puts "\nUser: #{message}\n"
        
        # Start conversation with block for real-time display
        @session.send_message(message) do |agent_name, response|
          if response[:content] && !response[:content].strip.empty?
            puts "\n#{agent_name}: #{response[:content]}"
            
            if response[:tool_calls]
              puts "  Tool calls: #{response[:tool_calls].map { |tc| tc[:function][:name] }.join(', ')}"
            end
          end
        end
        
        puts # Empty line for readability
      end

      def send_to_all_simple(message)
        # Original behavior - all agents respond independently
        responses = @session.send_message(message, simple_mode: true)
        responses.each do |agent_name, response|
          puts "\n#{agent_name}: #{response[:content] || '(no response)'}"
          
          if response[:tool_calls]
            puts "  Tool calls: #{response[:tool_calls].map { |tc| tc[:function][:name] }.join(', ')}"
          end
        end
      end
    end
  end
end