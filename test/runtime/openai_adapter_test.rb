# frozen_string_literal: true

require "test_helper"

class OpenaiAdapterTest < Minitest::Test
  def setup
    super
    @runtime = MultiAgent::Runtime::OpenaiAdapter.new(name: "test-openai")
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [{
            message: {
              role: "assistant",
              content: "Hello from OpenAI"
            }
          }]
        }.to_json
      )
  end

  def test_call_success
    ClimateControl.modify(OPENAI_API_KEY: "test-key") do
      messages = [{ role: "user", content: "Hello" }]
      response = @runtime.call(messages)
      
      assert_equal "assistant", response[:role]
      assert_equal "Hello from OpenAI", response[:content]
    end
  end

  def test_call_with_tools
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(body: hash_including("tools"))
      .to_return(
        status: 200,
        body: {
          choices: [{
            message: {
              role: "assistant",
              content: nil,
              tool_calls: [{
                id: "call_123",
                type: "function",
                function: {
                  name: "search",
                  arguments: '{"query": "test"}'
                }
              }]
            }
          }]
        }.to_json
      )

    ClimateControl.modify(OPENAI_API_KEY: "test-key") do
      tools = [{ type: "function", function: { name: "search" } }]
      response = @runtime.call([{ role: "user", content: "Search for test" }], tools: tools)
      
      assert_nil response[:content]
      assert_equal 1, response[:tool_calls].size
      assert_equal "search", response[:tool_calls].first[:function][:name]
    end
  end

  def test_missing_api_key
    assert_raises(RuntimeError) do
      @runtime.call([{ role: "user", content: "Hello" }])
    end
  end
end