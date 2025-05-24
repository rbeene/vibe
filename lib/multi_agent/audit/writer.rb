# frozen_string_literal: true

require "digest"
require "json"

module MultiAgent
  module Audit
    class Writer
      def initialize(path: "audit.jsonl")
        @path = path
        @logger = SemanticLogger[self.class]
      end

      def write(event_type, actor, data = {})
        entry = {
          id: SecureRandom.uuid,
          timestamp: Time.now.iso8601(6),
          event_type: event_type,
          actor: actor,
          data: data
        }
        
        # Add signature
        entry[:signature] = sign(entry)
        
        File.open(@path, "a") do |f|
          f.puts(entry.to_json)
        end
        
        @logger.info("Audit entry written", 
                     event_type: event_type,
                     actor: actor,
                     id: entry[:id])
      end

      def verify
        return true unless File.exist?(@path)
        
        valid = true
        File.readlines(@path).each_with_index do |line, index|
          entry = JSON.parse(line, symbolize_names: true)
          signature = entry.delete(:signature)
          
          if sign(entry) != signature
            @logger.error("Invalid audit entry", line: index + 1)
            valid = false
          end
        end
        
        valid
      end

      private

      def sign(entry)
        data = entry.reject { |k, _| k == :signature }
        Digest::SHA256.hexdigest(data.to_json)
      end
    end
  end
end