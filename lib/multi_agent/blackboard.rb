# frozen_string_literal: true

require "json"
require "fileutils"
require "monitor"

module MultiAgent
  class Blackboard
    include MonitorMixin
    attr_reader :entries, :trace

    @instances = {}

    def self.current(trace:)
      @instances[trace] ||= new(trace: trace)
    end

    def initialize(path: "tmp/blackboard.jsonl", trace: nil)
      super()
      @path = path
      @trace = trace
      @entries = []
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
      
      synchronize do
        @entries << { ts: Time.now.utc, data: entry }
        
        File.open(@path, "a") do |f|
          f.puts(entry.to_json)
        end
      end
      
      @logger.debug("Blackboard write", agent: agent_name, key: key)
    end

    def <<(item)
      synchronize { @entries << { ts: Time.now.utc, data: item } }
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
      synchronize do
        @entries.clear
        File.delete(@path) if File.exist?(@path)
      end
      @logger.info("Blackboard cleared")
    end
  end
end