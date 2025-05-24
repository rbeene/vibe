# frozen_string_literal: true

require "test_helper"

class CompilerTest < Minitest::Test
  def setup
    super
    @compiler = MultiAgent::Markdown::Compiler.new
    FileUtils.mkdir_p("workflows")
  end

  def test_compile_workflow
    File.write("workflows/test.md", <<~MD)
      ---
      name: "test_workflow"
      concurrency: 2
      ---
      # Test Workflow
      This is a test workflow.
    MD

    output = @compiler.compile("workflows/test.md")
    
    assert File.exist?(output)
    assert_match %r{tmp/ir/workflows/test.json}, output
    
    graph = MultiAgent::IR::Serializer.load(output)
    assert_equal 1, graph.nodes.size
    assert_equal "test", graph.nodes.first.id
  end

  def test_compile_with_dependencies
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

    output = @compiler.compile("workflows/with_deps.md")
    graph = MultiAgent::IR::Serializer.load(output)
    
    assert_equal 1, graph.edges.size
    assert_equal "helper", graph.edges.first.source
  end
end