# frozen_string_literal: true

require "securerandom"
require "dry-struct"

module MultiAgent
  module Runtime
    class Base < Dry::Struct
      attribute :name, Types::String
      attribute :trace_id, Types::String.default { SecureRandom.uuid }
      
      def initialize(*)
        super
        @logger = SemanticLogger[self.class]
      end

      # @abstract
      def call(messages, tools: [], **options)
        raise NotImplementedError
      end

      # @abstract
      def self.capabilities
        raise NotImplementedError
      end

      def lifecycle_start(agent_name)
        @logger.info("Runtime lifecycle start", 
                     agent_name: agent_name, 
                     runtime: name,
                     trace_id: trace_id)
      end

      def lifecycle_end(agent_name, duration)
        @logger.info("Runtime lifecycle end",
                     agent_name: agent_name,
                     runtime: name,
                     trace_id: trace_id,
                     duration_ms: duration)
      end

      protected

      def log_request(messages, tools)
        @logger.debug("Runtime request",
                      runtime: name,
                      trace_id: trace_id,
                      message_count: messages.size,
                      tool_count: tools.size)
      end

      def log_response(response, duration)
        @logger.debug("Runtime response",
                      runtime: name,
                      trace_id: trace_id,
                      duration_ms: duration,
                      response_preview: response.to_s[0..100])
      end
    end
  end
end