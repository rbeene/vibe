# frozen_string_literal: true

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
                       content: "[MOCK-RESPONSE]"
                     }
                   end

        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
        log_response(response, duration)

        response
      end
    end
  end
end