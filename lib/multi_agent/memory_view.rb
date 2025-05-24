# frozen_string_literal: true

module MultiAgent
  class MemoryView
    def initialize(agent_name, window_size: 10)
      @agent_name = agent_name
      @window_size = window_size
      @history = []
      @logger = SemanticLogger[self.class]
    end

    def add(message)
      @history << {
        timestamp: Time.now.iso8601(6),
        message: message
      }
      
      # Maintain sliding window
      if @history.size > @window_size
        @history.shift
      end
      
      @logger.debug("Memory added", 
                    agent: @agent_name, 
                    history_size: @history.size)
    end

    def recent(n = nil)
      n ? @history.last(n) : @history
    end

    def to_messages
      @history.map { |h| h[:message] }
    end

    def clear
      @history.clear
      @logger.debug("Memory cleared", agent: @agent_name)
    end
  end
end