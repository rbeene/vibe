# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Markdown::Compiler do
  let(:compiler) { described_class.new }

  before do
    FileUtils.mkdir_p("workflows")
  end

  describe "#compile" do
    it "compiles a workflow" do
      File.write("workflows/test.md", <<~MD)
        ---
        name: "test_workflow"
        concurrency: 2
        ---
        # Test Workflow
        This is a test workflow.
      MD

      output = compiler.compile("workflows/test.md")
      
      expect(File.exist?(output)).to be true
      expect(output).to match(%r{tmp/ir/workflows/test.json})
      
      graph = MultiAgent::IR::Serializer.load(output)
      expect(graph.nodes.size).to eq(1)
      expect(graph.nodes.first.id).to eq("test")
    end

    it "compiles with dependencies" do
      File.write("agents/helper.md", <<~MD)
        ---
        name: "helper"
        model: "gpt-4o-mini"
        ---
        # Helper Agent
      MD

      File.write("workflows/with_deps.md", <<~MD)
        ---
        name: "with_deps"
        ---
        # Workflow with Dependencies
        Uses @helper agent.
      MD

      output = compiler.compile("workflows/with_deps.md")
      graph = MultiAgent::IR::Serializer.load(output)
      
      expect(graph.edges.size).to eq(1)
      expect(graph.edges.first.source).to eq("helper")
    end
  end
end