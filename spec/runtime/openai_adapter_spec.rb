# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Runtime::OpenaiAdapter do
  let(:runtime) { described_class.new(name: "test-openai") }

  before do
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

  describe "#call" do
    context "with valid API key" do
      it "returns successful response" do
        ClimateControl.modify(OPENAI_API_KEY: "test-key") do
          messages = [{ role: "user", content: "Hello" }]
          response = runtime.call(messages)
          
          expect(response[:role]).to eq("assistant")
          expect(response[:content]).to eq("Hello from OpenAI")
        end
      end
    end

    context "with tools" do
      before do
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
      end

      it "returns tool calls" do
        ClimateControl.modify(OPENAI_API_KEY: "test-key") do
          tools = [{ type: "function", function: { name: "search" } }]
          response = runtime.call([{ role: "user", content: "Search for test" }], tools: tools)
          
          expect(response[:content]).to be_nil
          expect(response[:tool_calls].size).to eq(1)
          expect(response[:tool_calls].first[:function][:name]).to eq("search")
        end
      end
    end

    context "without API key" do
      it "raises error" do
        expect {
          runtime.call([{ role: "user", content: "Hello" }])
        }.to raise_error(RuntimeError)
      end
    end
  end
end