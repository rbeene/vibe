# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Runtime::Stub do
  let(:runtime) { described_class.new(name: "test-stub") }

  describe ".capabilities" do
    it "returns correct capabilities" do
      caps = described_class.capabilities
      
      expect(caps[:streaming]).to eq(false)
      expect(caps[:tool_calling]).to eq(true)
      expect(caps[:max_tokens]).to eq(4096)
    end
  end

  describe "#call" do
    context "without tools" do
      it "returns mock response" do
        messages = [
          { role: "user", content: "Hello" }
        ]
        
        response = runtime.call(messages)
        
        expect(response[:role]).to eq("assistant")
        expect(response[:content]).to eq("[MOCK-RESPONSE]")
      end
    end

    context "with tools" do
      it "returns tool calls" do
        messages = [{ role: "user", content: "Search for something" }]
        tools = [{ name: "search", description: "Search tool" }]
        
        response = runtime.call(messages, tools: tools)
        
        expect(response[:role]).to eq("assistant")
        expect(response[:content]).to be_nil
        expect(response[:tool_calls].size).to eq(1)
        expect(response[:tool_calls].first[:function][:name]).to eq("search")
      end
    end

    it "logs runtime requests and responses" do
      logger_output = capture_logger_output do
        runtime.call([{ role: "user", content: "Test" }])
      end
      
      expect(logger_output).to match(/Runtime request/)
      expect(logger_output).to match(/Runtime response/)
    end
  end

  private

  def capture_logger_output
    original = SemanticLogger.appenders.first
    io = StringIO.new
    SemanticLogger.add_appender(io: io, formatter: :json)
    SemanticLogger.appenders.delete(original)
    
    yield
    
    io.string
  ensure
    SemanticLogger.appenders.clear
    SemanticLogger.add_appender(original) if original
  end
end