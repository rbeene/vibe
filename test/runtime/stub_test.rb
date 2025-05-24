# frozen_string_literal: true

require "test_helper"

class StubRuntimeTest < Minitest::Test
  def setup
    super
    @runtime = MultiAgent::Runtime::Stub.new(name: "test-stub")
  end

  def test_capabilities
    caps = MultiAgent::Runtime::Stub.capabilities
    
    assert_equal false, caps[:streaming]
    assert_equal true, caps[:tool_calling]
    assert_equal 4096, caps[:max_tokens]
  end

  def test_call_without_tools
    messages = [
      { role: "user", content: "Hello" }
    ]
    
    response = @runtime.call(messages)
    
    assert_equal "assistant", response[:role]
    assert_equal "[MOCK-RESPONSE]", response[:content]
  end

  def test_call_with_tools
    messages = [{ role: "user", content: "Search for something" }]
    tools = [{ name: "search", description: "Search tool" }]
    
    response = @runtime.call(messages, tools: tools)
    
    assert_equal "assistant", response[:role]
    assert_nil response[:content]
    assert_equal 1, response[:tool_calls].size
    assert_equal "search", response[:tool_calls].first[:function][:name]
  end

  def test_logging
    logger_output = capture_logger_output do
      @runtime.call([{ role: "user", content: "Test" }])
    end
    
    assert_match(/Runtime request/, logger_output)
    assert_match(/Runtime response/, logger_output)
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