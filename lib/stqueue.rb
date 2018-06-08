# frozen_string_literal: true

require 'pry'
raise 'Rails is not defined' unless defined? ::Rails

require "open4"
require 'stqueue/version'
require 'stqueue/error'
require 'stqueue/runner'
require 'stqueue/monitor'
require 'stqueue/base'

module STQueue # :nodoc:
  WRONG_LOG_DIR_TYPE_ERROR = 'STQueue log_dir must be a `Pathname`. Use `Rails.root.join(...)` to define it.'.freeze

  @config  = OpenStruct.new
  @monitor = STQueue::Monitor.new

  class << self
    def configure
      yield self
      STQueue::Base.setup! if sidekiq_connected?
    end

    def sidekiq_connected?
      Rails.application.config.active_job.queue_adapter == :sidekiq
    rescue StandardError
      false
    end

    def log_dir=(dir)
      raise STQueue::Error, WRONG_LOG_DIR_TYPE_ERROR unless dir.is_a? Pathname
      @config.log_dir = dir
    end

    def log_dir
      @config.log_dir
    end

    def pid_file=(file)
      @monitor.set_file(file).load!
    end

    def monitor
      @monitor
    end
  end
end
