# frozen_string_literal: true

module STQueue
  class Process # :nodoc:
    class << self
      def all
        STQueue.store.queues.map do |name, data|
          process = Process.new(data['pid'], name, data['concurrency'])
          process.kill if process.pid && !process.running?
          process
        end
      end

      def first
        all.first
      end

      def find_or_initialize_by(pid: nil, queue_name: nil)
        return if queue_name.blank? && pid.blank?
        find_by(pid: pid, queue_name: queue_name) || initialize_by(queue_name)
      end

      def find_by(pid: nil, queue_name: nil)
        return if queue_name.blank? && pid.blank?
        all.find do |process|
          (pid.present? && process.pid == pid) || (queue_name.present? && process.queue_name == queue_name)
        end
      end

      def initialize_by(queue_name, concurrency = STQueue.concurrency)
        return if queue_name.blank?
        new(nil, queue_name, concurrency)
      end

      def create(queue_name, concurrency = STQueue.concurrency)
        initialize_by(queue_name, concurrency).start
      end
    end

    attr_reader :pid, :queue_name, :concurrency, :log_file_path

    def initialize(pid, queue_name, concurrency)
      @pid           = pid
      @queue_name    = queue_name
      @concurrency   = concurrency || STQueue.concurrency
      @log_file_path = STQueue.log_dir.join("#{queue_name}.log")
    end

    def set(field, value)
      prev_value = instance_variable_get("@#{field}")
      return if prev_value == value
      instance_variable_set("@#{field}", value)
      restart if field == :concurrency
    end

    def running?
      `ps -ax -r -o pid`.split("\n").drop(1).map!(&:strip).include?(pid.to_s)
    end

    def kill
      STQueue.store.null(queue_name)
      Sidekiq.logger.info("[STOPPING] STQueue for '#{queue_name}' | pid '#{pid}' | concurrency '#{concurrency}'")
      system("kill #{pid}")
      @pid = nil
      self
    end

    def start
      return if running?
      @pid = `bundle exec sidekiq \
                  -c #{concurrency} \
                  -q #{queue_name} \
                  >> #{log_file_path} 2>&1 & \
                  echo $!`.to_i
      STQueue.store.replace(queue_name, pid, concurrency)
      Sidekiq.logger.info("[STARTED] STQueue for '#{queue_name}' | pid '#{pid}' | concurrency '#{concurrency}'")
      self
    end

    def restart
      kill
      start
    end
  end
end
