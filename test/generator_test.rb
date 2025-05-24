# frozen_string_literal: true

require "test_helper"

class GeneratorTest < Minitest::Test
  def setup
    super
    @generator = MultiAgent::Generator.new
  end

  def test_generate_agent
    path = @generator.generate("agent", "test_agent")
    
    assert File.exist?(path)
    assert_equal "agents/test_agent.md", path
    
    content = File.read(path)
    assert_match(/name: "test_agent"/, content)
    assert_match(/# Test_agent Agent/, content)
  end

  def test_generate_task
    path = @generator.generate("task", "test_task")
    
    assert File.exist?(path)
    assert_equal "tasks/test_task.md", path
    
    content = File.read(path)
    assert_match(/name: "test_task"/, content)
    assert_match(/timeout: 300/, content)
  end

  def test_generate_workflow
    path = @generator.generate("workflow", "test_workflow")
    
    assert File.exist?(path)
    assert_equal "workflows/test_workflow.md", path
    
    content = File.read(path)
    assert_match(/concurrency: 4/, content)
  end

  def test_generate_plugin
    path = @generator.generate("plugin", "test_plugin")
    
    assert Dir.exist?(path)
    assert_equal "plugins/test_plugin", path
    assert File.exist?("#{path}/manifest.yml")
    assert File.exist?("#{path}/test_plugin.rb")
    
    manifest = YAML.load_file("#{path}/manifest.yml")
    assert_equal "test_plugin", manifest["name"]
    assert_equal "0.1.0", manifest["version"]
  end
end