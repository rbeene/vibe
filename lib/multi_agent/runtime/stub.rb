# frozen_string_literal: true

require "securerandom"

module MultiAgent
  module Runtime
    class Stub < Base
      def self.capabilities
        {
          streaming: false,
          tool_calling: true,
          parallel_tools: false,
          max_tokens: 4096
        }
      end

      def call(messages, tools: [], **options)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        log_request(messages, tools)

        # Simulate some work with a small delay
        sleep(0.01) if ENV["SIMULATE_WORK"] == "true"

        # Extract agent name from system message if available
        agent_name = "Agent"
        system_msg = messages.find { |m| m[:role] == "system" }
        if system_msg && system_msg[:content] =~ /You are (\w+)/
          agent_name = $1
        end

        # Generate more intelligent mock responses based on context
        last_user_msg = messages.reverse.find { |m| m[:role] == "user" }
        content = generate_mock_response(agent_name, last_user_msg, messages)

        # Deterministic fake response
        response = if tools.any?
                     {
                       role: "assistant",
                       content: nil,
                       tool_calls: [{
                         id: "call_mock_#{SecureRandom.hex(4)}",
                         type: "function",
                         function: {
                           name: tools.first[:name],
                           arguments: "{}"
                         }
                       }]
                     }
                   else
                     {
                       role: "assistant",
                       content: content
                     }
                   end

        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
        log_response(response, duration)

        response
      end

      private

      def generate_mock_response(agent_name, last_msg, all_messages)
        return "[No message to respond to]" unless last_msg

        # Check if this is a conversation with other agents
        if all_messages.any? { |m| m[:content]&.include?("[") && m[:content]&.include?("]:")}
          # In conversation mode, generate contextual responses
          case agent_name.downcase
          when "support-bot"
            "I can help with that! From a customer support perspective, #{generate_contextual_snippet(last_msg[:content])}"
          when "research"
            "Based on my analysis, #{generate_contextual_snippet(last_msg[:content])}. I'd recommend looking into this further."
          when "facilitator"
            "That's an interesting point. To build on what was said, #{generate_contextual_snippet(last_msg[:content])}"
          else
            "[#{agent_name} responds thoughtfully to: #{last_msg[:content].to_s[0..50]}...]"
          end
        else
          # Simple single-agent response
          "[#{agent_name} mock response to: #{last_msg[:content].to_s[0..50]}...]"
        end
      end

      def generate_contextual_snippet(content)
        # Extract key terms for a more contextual response
        key_terms = content.to_s.downcase.scan(/\b(ruby|rails|python|javascript|api|database|framework|learn|help)\b/).flatten.first
        
        if key_terms
          "this relates to #{key_terms}"
        else
          "this is an important consideration"
        end
      end
    end
  end
end