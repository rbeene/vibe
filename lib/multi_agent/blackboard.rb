# frozen_string_literal: true

require "json"
require "fileutils"

module MultiAgent
  class Blackboard
    def initialize(path: "tmp/blackboard.jsonl")
      @path = path
      @logger = SemanticLogger[self.class]
      FileUtils.mkdir_p(File.dirname(@path))
    end

    def write(agent_name, key, value)
      entry = {
        timestamp: Time.now.iso8601(6),
        agent: agent_name,
        key: key,
        value: value
      }
      
      File.open(@path, "a") do |f|
        f.puts(entry.to_json)
      end
      
      @logger.debug("Blackboard write", agent: agent_name, key: key)
    end

    def read(key = nil)
      return [] unless File.exist?(@path)
      
      entries = File.readlines(@path).map { |line| JSON.parse(line, symbolize_names: true) }
      
      if key
        entries.select { |e| e[:key] == key }
      else
        entries
      end
    end

    def read_by_agent(agent_name)
      read.select { |e| e[:agent] == agent_name }
    end

    def clear
      File.delete(@path) if File.exist?(@path)
      @logger.info("Blackboard cleared")
    end
  end
end