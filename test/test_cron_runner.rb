# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/macaw_framework/core/cron_runner"

class TestCronRunner < Minitest::Test
  class MockMacaw
    attr_accessor :macaw_log
  end

  class MockLog
    attr_reader :count

    def initialize
      @count = []
    end

    def info(_msg); end

    def error(msg)
      @count << msg
    end
  end

  def test_start_cron_job_thread
    macaw = MockMacaw.new
    macaw.macaw_log = nil
    msg_array = []

    cron_runner = CronRunner.new(macaw)
    cron_runner.start_cron_job_thread(1, 1, "TestJob") do
      msg_array << "Job executed"
    end
    sleep(3)

    assert_includes msg_array, "Job executed"
  end

  def test_error_handling
    macaw = MockMacaw.new
    macaw.macaw_log = MockLog.new

    cron_runner = CronRunner.new(macaw)
    thread = cron_runner.start_cron_job_thread(1, 0, "ErrorJob") { raise "Test error" }
    sleep(3)

    assert_includes macaw.macaw_log.count, "Error executing cron job with name ErrorJob: Test error"
    thread.kill
  end

  def test_interval_and_start_delay_validation
    macaw = MockMacaw.new
    macaw.macaw_log = nil

    cron_runner = CronRunner.new(macaw)

    assert_raises(RuntimeError) { cron_runner.start_cron_job_thread(-1, 1, "NegativeIntervalJob") {} }
    assert_raises(RuntimeError) { cron_runner.start_cron_job_thread(1, -1, "NegativeStartDelayJob") {} }
    assert_raises(RuntimeError) { cron_runner.start_cron_job_thread(0, 1, "ZeroIntervalJob") {} }
  end
end
