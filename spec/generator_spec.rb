# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Generator do
  let(:generator) { described_class.new }

  describe "#generate" do
    context "when generating an agent" do
      it "creates agent file with correct content" do
        path = generator.generate("agent", "test_agent")
        
        expect(File.exist?(path)).to be true
        expect(path).to eq("agents/test_agent.md")
        
        content = File.read(path)
        expect(content).to match(/name: "test_agent"/)
        expect(content).to match(/# Test_agent Agent/)
      end
    end

    context "when generating a task" do
      it "creates task file with correct content" do
        path = generator.generate("task", "test_task")
        
        expect(File.exist?(path)).to be true
        expect(path).to eq("tasks/test_task.md")
        
        content = File.read(path)
        expect(content).to match(/name: "test_task"/)
        expect(content).to match(/timeout: 300/)
      end
    end

    context "when generating a workflow" do
      it "creates workflow file with correct content" do
        path = generator.generate("workflow", "test_workflow")
        
        expect(File.exist?(path)).to be true
        expect(path).to eq("workflows/test_workflow.md")
        
        content = File.read(path)
        expect(content).to match(/concurrency: 4/)
      end
    end

    context "when generating a plugin" do
      it "creates plugin directory with manifest and code files" do
        path = generator.generate("plugin", "test_plugin")
        
        expect(Dir.exist?(path)).to be true
        expect(path).to eq("plugins/test_plugin")
        expect(File.exist?("#{path}/manifest.yml")).to be true
        expect(File.exist?("#{path}/test_plugin.rb")).to be true
        
        manifest = YAML.load_file("#{path}/manifest.yml")
        expect(manifest["name"]).to eq("test_plugin")
        expect(manifest["version"]).to eq("0.1.0")
      end
    end
  end
end