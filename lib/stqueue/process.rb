# frozen_string_literal: true

module STQueue
  class Process # :nodoc:
    class << self
      def all
        STQueue.store.queues.map do |name, data|
          process = Process.new(data['pid'], name, data['concurrency'])
          process.set(:pid, nil) if process.stopped?
          process
        end
      end

      def first
        all.first
      end

      def running
        all.select(&:running?)
      end

      def stopped
        all.select(&:stopped?)
      end

      def find_or_initialize_by(queue_name: nil)
        return if queue_name.blank?
        find_by(queue_name: queue_name) || initialize_by(queue_name: queue_name)
      end

      def find_by(queue_name: nil)
        return if queue_name.blank?
        found = all.find { |process| process.queue_name.to_s == queue_name.to_s }
        from_sidekiq = find_by_sidekiq_process(queue_name)
        return found if from_sidekiq.blank?
        return from_sidekiq.save if found.blank?
        found.set(:pid, from_sidekiq.pid).save
      end

      def initialize_by(queue_name: nil, concurrency: STQueue.concurrency)
        return if queue_name.blank?
        new(nil, queue_name, concurrency)
      end

      def create(queue_name, concurrency = STQueue.concurrency)
        initialize_by(queue_name: queue_name, concurrency: concurrency).start
      end

      def find_by_sidekiq_process(queue_name)
        sidekiq_process = Sidekiq::ProcessSet.new.find { |process| process['queues'].include?(queue_name.to_s) }
        return if sidekiq_process.blank? || sidekiq_process.stopping?
        new(sidekiq_process['pid'], queue_name, sidekiq_process['concurrency'])
      end
    end

    attr_reader :pid, :queue_name, :concurrency, :log_file_path

    def initialize(pid, queue_name, concurrency)
      @pid           = pid
      @queue_name    = queue_name.to_sym
      @concurrency   = concurrency || STQueue.concurrency
      @log_file_path = STQueue.log_dir.join("#{queue_name}.log")
    end

    def set(field, value)
      prev_value = instance_variable_get("@#{field}")
      return self if prev_value == value
      instance_variable_set("@#{field}", value)
      self
    end

    def running?
      `ps -ax -o pid`.split("\n").drop(1).map!(&:strip).include?(pid.to_s) ||
        sidekiq_process.present?
    end

    def stopped?
      !running?
    end

    def need_to_kill?
      jobs_exists = Sidekiq::Queue.all.find { |q| q.name == queue_name.to_s }&.size&.positive?
      retries_exists = !!Sidekiq::RetrySet.new.find { |j| j.queue == queue_name.to_s }
      return running? && !jobs_exists && !retries_exists
    end

    def kill
      return self if stopped?
      Sidekiq.logger.info("[STOPPING] STQueue for '#{queue_name}' | pid '#{pid}' | concurrency '#{concurrency}'")
      `kill -term #{pid}`
      sleep 1 while running?
      @pid = nil
      STQueue.store.null(queue_name)
      self
    end

    def self_kill
      Sidekiq.logger.info("[STOPPING] STQueue for '#{queue_name}' | pid '#{pid}' | concurrency '#{concurrency}'")
      exec("true")
    end

    def save
      STQueue.store.replace(queue_name, pid, concurrency)
      self
    end

    def start
      return self if running?
      @pid = `bundle exec sidekiq \
                  -c #{concurrency} \
                  -q #{queue_name} \
                  >> #{log_file_path} 2>&1 & \
                  echo $!`.to_i
      save
      Sidekiq.logger.info("[STARTED] STQueue for '#{queue_name}' | pid '#{pid}' | concurrency '#{concurrency}'")
      self
    end

    def restart
      kill
      start
    end

    def delete
      kill
      STQueue.store.pop(queue_name)
      nil
    end

    def sidekiq_process
      Sidekiq::ProcessSet.new.find do |process|
        process['queues'].include?(queue_name.to_s) && !process.stopping?
      end
    end
  end
end
