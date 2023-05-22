# frozen_string_literal: true

##
# This module is responsible to set up a new thread
# for each cron job defined
class CronRunner
  def initialize(macaw)
    @logger = macaw.macaw_log
    @macaw = macaw
  end

  ##
  # Will start a thread for the defined cron job
  # @param {Integer} interval
  # @param {Integer?} start_delay
  # @param {String} job_name
  # @param {Proc} block
  def start_cron_job_thread(interval, start_delay, job_name, &block)
    raise "interval can't be <= 0 and start_delay can't be < 0!" if interval <= 0 || start_delay.negative?

    @logger&.info("Starting thread for job #{job_name}")
    start_delay ||= 0
    thread = Thread.new do
      name = job_name
      interval_thread = interval
      unless start_delay.nil?
        @logger&.info("Job #{name} scheduled with delay. Will start running in #{start_delay} seconds.")
        sleep(start_delay)
      end

      loop do
        start_time = Time.now
        @logger&.info("Running job #{name}")
        block.call
        @logger&.info("Job #{name} executed with success. New execution in #{interval_thread} seconds.")

        execution_time = Time.now - start_time
        sleep_time = [interval_thread - execution_time, 0].max
        sleep(sleep_time)
      rescue StandardError => e
        @logger&.error("Error executing cron job with name #{name}: #{e.message}")
      end
    end
    sleep(1)
    @logger&.info("Thread for job #{job_name} started")
    thread
  end
end
