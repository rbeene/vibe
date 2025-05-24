# frozen_string_literal: true

require "dry/cli"

module MultiAgent
  module Command
    class CLI < Dry::CLI::Command
      def self.start(argv)
        Dry::CLI.new.tap do |cli|
          cli.register "compile", Compile
          cli.register "run", Run
          cli.register "evaluate", Evaluate
          cli.register "run_job", RunJob
          cli.register "new", New
          cli.register "plugins:list", PluginsList
        end.call(arguments: argv)
      end
    end

    class Compile < Dry::CLI::Command
      desc "Compile markdown to IR"
      argument :artefact, required: true, desc: "Path to markdown file"

      def call(artefact:, **)
        compiler = Markdown::Compiler.new
        output = compiler.compile(artefact)
        puts "Compiled to: #{output}"
      end
    end

    class Run < Dry::CLI::Command
      desc "Run a workflow"
      argument :workflow, required: true, desc: "Path to workflow markdown"
      option :runtime, default: nil, desc: "Runtime to use (stub, openai)"
      option :concurrency, type: :integer, default: nil, desc: "Concurrency level"

      def call(workflow:, runtime: nil, concurrency: nil, **)
        runtime ||= MultiAgent.config[:default_runtime]
        concurrency ||= MultiAgent.config[:concurrency]

        # Compile workflow
        compiler = Markdown::Compiler.new
        ir_path = compiler.compile(workflow)
        graph = IR::Serializer.load(ir_path)

        # Create runtime
        runtime_instance = case runtime
                          when "stub"
                            Runtime::Stub.new(name: "stub")
                          when "openai"
                            Runtime::OpenaiAdapter.new(name: "openai")
                          else
                            raise "Unknown runtime: #{runtime}"
                          end

        # Create structured logger
        run_logger = Log::Structured.new

        # Execute workflow
        dispatcher = Dispatcher.new(
          runtime: runtime_instance,
          concurrency: concurrency
        )

        run_logger.task_start(File.basename(workflow, ".md"))
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        
        dispatcher.execute(graph)
        
        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
        run_logger.task_end(File.basename(workflow, ".md"), duration)

        puts "Workflow executed successfully"
      end
    end

    class Evaluate < Dry::CLI::Command
      desc "Run an evaluation"
      argument :eval_file, required: true, desc: "Path to evaluation markdown"

      def call(eval_file:, **)
        puts "Evaluating: #{eval_file}"
        # Evaluation logic would go here
        puts "Evaluation complete"
      end
    end

    class RunJob < Dry::CLI::Command
      desc "Run a scheduled job"
      argument :job_file, required: true, desc: "Path to job markdown"

      def call(job_file:, **)
        runner = Job::Runner.new
        runner.run(job_file)
      end
    end

    class New < Dry::CLI::Command
      desc "Generate new artefact"
      argument :type, required: true, values: %w[agent task workflow job eval plugin]
      argument :name, required: true, desc: "Name of the artefact"

      def call(type:, name:, **)
        generator = Generator.new
        path = generator.generate(type, name)
        puts "Created: #{path}"
      end
    end

    class PluginsList < Dry::CLI::Command
      desc "List installed plugins"

      def call(**)
        loader = Plugin::Loader.new
        plugins = loader.list

        if plugins.empty?
          puts "No plugins installed"
        else
          puts "Installed plugins:"
          plugins.each do |plugin|
            puts "  - #{plugin[:name]} (v#{plugin[:version]}): #{plugin[:description]}"
          end
        end
      end
    end
  end
end