# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "multi_agent"
require "minitest/autorun"
require "webmock/minitest"
require "timecop"
require "climate_control"
require "fileutils"

class Minitest::Test
  def setup
    # Clean test directories
    %w[tmp log audit.jsonl].each do |path|
      FileUtils.rm_rf(path)
    end
  end

  def teardown
    Timecop.return
  end
end