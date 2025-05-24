# frozen_string_literal: true

require "spec_helper"

RSpec.describe MultiAgent::Job::Runner do
  let(:runner) { described_class.new }

  before do
    FileUtils.mkdir_p("jobs")
    FileUtils.mkdir_p("workflows")
  end

  describe "#run" do
    context "when job is scheduled to run" do
      it "executes the job" do
        Timecop.freeze(Time.parse("2024-01-01 09:00:00")) do
          File.write("jobs/test_job.md", <<~MD)
            ---
            name: "test_job"
            cron: "0 9 * * *"
            workflow: "test_workflow"
            ---
            # Test Job
          MD

          File.write("workflows/test_workflow.md", <<~MD)
            ---
            name: "test_workflow"
            ---
            # Test Workflow
          MD

          output = capture(:stdout) { runner.run("jobs/test_job.md") }
          expect(output).not_to match(/SKIPPED/)
        end
      end
    end

    context "when job is not scheduled to run" do
      it "skips the job" do
        Timecop.freeze(Time.parse("2024-01-01 10:00:00")) do
          File.write("jobs/test_job.md", <<~MD)
            ---
            name: "test_job"
            cron: "0 9 * * *"
            ---
            # Test Job
          MD

          output = capture(:stdout) { runner.run("jobs/test_job.md") }
          expect(output).to match(/SKIPPED/)
        end
      end
    end
  end

  private

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end
end