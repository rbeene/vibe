# frozen_string_literal: true

require "faraday"
require "json"

module MultiAgent
  module Runtime
    class OpenaiAdapter < Base
      API_URL = "https://api.openai.com/v1/chat/completions"

      def self.capabilities
        {
          streaming: true,
          tool_calling: true,
          parallel_tools: true,
          max_tokens: 128_000
        }
      end

      def call(messages, tools: [], **options)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        log_request(messages, tools)

        api_key = ENV[MultiAgent.config[:openai_api_key_env]]
        raise "OpenAI API key not found in ENV" unless api_key

        model = options[:model] || MultiAgent.config[:default_model]
        
        body = {
          model: model,
          messages: messages,
          temperature: options[:temperature] || 0.7,
          max_tokens: options[:max_tokens] || 1000
        }
        
        body[:tools] = tools if tools.any?

        response = connection(api_key).post do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = body.to_json
        end

        if response.status != 200
          raise "OpenAI API error: #{response.status} - #{response.body}"
        end

        result = JSON.parse(response.body, symbolize_names: true)
        message = result[:choices].first[:message]

        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
        log_response(message, duration)

        message
      end

      private

      def connection(api_key)
        @connection ||= Faraday.new(url: API_URL) do |f|
          f.request :authorization, "Bearer", api_key
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end