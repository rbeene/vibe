# frozen_string_literal: true

module MultiAgent
  module Command
    class Repl < Dry::CLI::Command
      desc "Interactive shell with live agents"

      argument :workflow, required: false, desc: ".md file (optional)"
      option   :runtime,  default: "stub", desc: "Runtime adapter"
      option   :concurrency, default: 4, type: :integer

      def call(workflow: nil, runtime: "openai", concurrency: 4, **)
        ir = nil
        if workflow
          compiler = Markdown::Compiler.new
          ir_path = compiler.compile(workflow)
          ir = IR::Serializer.load(ir_path)
        end
        
        session = MultiAgent::Repl::Session.new(ir: ir, runtime: runtime, concurrency: concurrency)
        MultiAgent::Repl::Shell.new(session).start
      end
    end
  end
end
