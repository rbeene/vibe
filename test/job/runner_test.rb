# frozen_string_literal: true

require "test_helper"

class JobRunnerTest < Minitest::Test
  def setup
    super
    @runner = MultiAgent::Job::Runner.new
    FileUtils.mkdir_p("jobs")
    FileUtils.mkdir_p("workflows")
  end

  def test_job_runs_when_scheduled
    # Create a job scheduled to run now
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

      output = capture_subprocess_io do
        @runner.run("jobs/test_job.md")
      end

      refute_match(/SKIPPED/, output.join)
    end
  end

  def test_job_skips_when_not_scheduled
    # Create a job not scheduled to run now
    Timecop.freeze(Time.parse("2024-01-01 10:00:00")) do
      File.write("jobs/test_job.md", <<~MD)
        ---
        name: "test_job"
        cron: "0 9 * * *"
        ---
        # Test Job
      MD

      output = capture_subprocess_io do
        @runner.run("jobs/test_job.md")
      end

      assert_match(/SKIPPED/, output.join)
    end
  end
end