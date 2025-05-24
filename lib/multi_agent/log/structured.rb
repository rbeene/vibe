# frozen_string_literal: true

require "json"
require "fileutils"

module MultiAgent
  module Log
    class Structured
      def initialize(run_id: nil)
        @run_id = run_id || "run-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
        @path = "log/#{@run_id}.jsonl"
        FileUtils.mkdir_p("log")
      end

      def log(event_type, data = {})
        entry = {
          timestamp: Time.now.iso8601(6),
          run_id: @run_id,
          event: event_type,
          data: data
        }
        
        File.open(@path, "a") do |f|
          f.puts(entry.to_json)
        end
      end

      def task_start(task_name, metadata = {})
        log("task_start", { task: task_name }.merge(metadata))
      end

      def task_end(task_name, duration_ms, metadata = {})
        log("task_end", { 
          task: task_name, 
          duration_ms: duration_ms 
        }.merge(metadata))
      end

      def model_call(model, messages, response, duration_ms)
        log("model_call", {
          model: model,
          message_count: messages.size,
          response_preview: response.to_s[0..100],
          duration_ms: duration_ms
        })
      end

      def error(message, details = {})
        log("error", { message: message }.merge(details))
      end
    end
  end
end