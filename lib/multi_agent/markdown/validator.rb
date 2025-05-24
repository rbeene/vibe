# frozen_string_literal: true

require "json-schema"

module MultiAgent
  module Markdown
    class Validator
      SCHEMAS = {
        "agents" => {
          "type" => "object",
          "required" => ["name", "model"],
          "properties" => {
            "name" => { "type" => "string" },
            "model" => { "type" => "string" },
            "temperature" => { "type" => "number" },
            "max_tokens" => { "type" => "integer" }
          }
        },
        "tasks" => {
          "type" => "object",
          "required" => ["name"],
          "properties" => {
            "name" => { "type" => "string" },
            "timeout" => { "type" => "integer" },
            "retries" => { "type" => "integer" }
          }
        },
        "workflows" => {
          "type" => "object",
          "required" => ["name"],
          "properties" => {
            "name" => { "type" => "string" },
            "concurrency" => { "type" => "integer" }
          }
        }
      }.freeze

      def validate(front_matter, path)
        type = determine_type(path)
        schema = SCHEMAS[type]
        
        return { error: "Unknown artifact type" } unless schema
        
        errors = JSON::Validator.fully_validate(schema, front_matter)
        
        if errors.any?
          { error: "Validation failed: #{errors.join(', ')}" }
        else
          { valid: true }
        end
      end

      private

      def determine_type(path)
        case path
        when /agents\//  then "agents"
        when /tasks\//   then "tasks"
        when /workflows\// then "workflows"
        else nil
        end
      end
    end
  end
end