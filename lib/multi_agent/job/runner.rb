# frozen_string_literal: true

require "fugit"

module MultiAgent
  module Job
    class Runner
      def initialize
        @logger = SemanticLogger[self.class]
      end

      def run(job_path)
        content = File.read(job_path)
        front_matter = extract_front_matter(content)
        
        cron = front_matter["cron"]
        unless cron
          @logger.error("No cron schedule found", job_path: job_path)
          return
        end
        
        schedule = Fugit.parse(cron)
        next_run = schedule.next_time
        
        @logger.info("Job schedule", 
                     job: File.basename(job_path),
                     cron: cron,
                     next_run: next_run.to_s)
        
        # Check if should run now (within 1 minute window)
        if should_run_now?(schedule)
          execute_job(job_path, front_matter)
        else
          @logger.info("Job skipped - not scheduled", 
                       job: File.basename(job_path),
                       next_run: next_run.to_s)
          puts "SKIPPED"
        end
      end

      private

      def extract_front_matter(content)
        if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
          YAML.safe_load($1, permitted_classes: [Symbol])
        else
          {}
        end
      end

      def should_run_now?(schedule)
        now = Time.now
        
        # Check if we're at the exact scheduled time (within 1 second)
        next_time = schedule.next_time(now - 1)
        if next_time && (next_time.to_f - now.to_f).abs < 1
          return true
        end
        
        # Otherwise, check if previous scheduled time was within last minute
        prev = schedule.previous_time(now)
        return false unless prev
        
        # Convert EtOrbi::EoTime to seconds since epoch for comparison
        prev_seconds = prev.to_f
        now_seconds = now.to_f
        (now_seconds - prev_seconds) < 60
      end

      def execute_job(job_path, metadata)
        @logger.info("Executing job", job: File.basename(job_path))
        
        workflow = metadata["workflow"]
        if workflow
          # Compile and run the workflow
          compiler = Markdown::Compiler.new
          ir_path = compiler.compile("workflows/#{workflow}.md")
          graph = IR::Serializer.load(ir_path)
          
          runtime_name = metadata["runtime"] || MultiAgent.config[:default_runtime]
          runtime = create_runtime(runtime_name)
          
          dispatcher = Dispatcher.new(
            runtime: runtime,
            concurrency: metadata["concurrency"] || 1
          )
          
          dispatcher.execute(graph)
        end
        
        @logger.info("Job execution complete", job: File.basename(job_path))
      end

      def create_runtime(name)
        case name
        when "stub"
          Runtime::Stub.new(name: "stub")
        when "openai"
          Runtime::OpenaiAdapter.new(name: "openai")
        else
          raise "Unknown runtime: #{name}"
        end
      end
    end
  end
end