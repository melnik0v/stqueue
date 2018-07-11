# frozen_string_literal: true

require "English"
require 'stqueue/version'
require 'stqueue/error'
require 'stqueue/process'
require 'stqueue/monitor'
require 'stqueue/store/base'
require 'stqueue/store/redis_store'
require 'stqueue/store/file_store'
require 'stqueue/base'

module STQueue # :nodoc:
  DEFAULT_CONCURRENCY       = 1
  AVAILABLE_STORES          = %i[redis file].freeze
  QUEUE_PREFIX              = 'stqueued'
  WRONG_LOG_DIR_TYPE_ERROR  = 'You should set config.log_dir as `Pathname`. Use `Rails.root.join(...)` to define it.'
  WRONG_PIDS_DIR_TYPE_ERROR = 'You should set config.pids_dir as `Pathname`. Use `Rails.root.join(...)` to define it.'
  WRONG_STORE_TYPE          = "Wrong store type. Available store types is #{AVAILABLE_STORES}"

  @config = ::OpenStruct.new(concurrency: 1, redis_url: 'redis://localhost:6379/12')

  class << self
    delegate :log_dir, :pids_dir, :store, :store_type=, :store_type, :enabled, :enabled=,
             :concurrency, :redis_url, :redis_url=, to: :@config

    def configure
      yield self
      @config.enabled &&= !Rails.env.test? && defined?(::Rails) && sidekiq_connected?
      init!
    end

    def init!
      return unless enabled
      raise Error, WRONG_LOG_DIR_TYPE_ERROR  unless log_dir.is_a? Pathname
      raise Error, WRONG_PIDS_DIR_TYPE_ERROR if store_type == :file && !pids_dir.is_a?(Pathname)
      @config.store = "STQueue::Store::#{store_type.to_s.capitalize}Store".safe_constantize.new
      monitor.health_check!
    end

    def monitor
      @monitor ||= STQueue::Monitor.new
    end

    def log_dir=(dir)
      return unless enabled
      @config.log_dir = dir
      FileUtils.mkdir(log_dir) unless Dir.exist?(log_dir)
    end

    def pids_dir=(dir)
      return unless enabled
      @config.pids_dir = dir
      FileUtils.mkdir(pids_dir) unless Dir.exist?(pids_dir)
    end

    def store_type=(store_type)
      return unless enabled
      raise Error, WRONG_STORE_TYPE unless AVAILABLE_STORES.include? store_type.to_sym
      @config.store_type = store_type
    end

    def concurrency=(value)
      @config.concurrency = value || DEFAULT_CONCURRENCY
    end

    def sidekiq_connected?
      Rails.application.config.active_job.queue_adapter == :sidekiq
    rescue StandardError
      false
    end
  end
end
