# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "multi_agent"
require "webmock/rspec"
require "timecop"
require "climate_control"
require "fileutils"
require "tmpdir"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.around(:each) do |example|
    # Create a temporary directory for each test
    Dir.mktmpdir("multi_agent_test") do |tmpdir|
      # Change to the temporary directory
      Dir.chdir(tmpdir) do
        example.run
      end
    end
  end

  config.after(:each) do
    Timecop.return
  end
end