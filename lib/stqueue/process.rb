# frozen_string_literal: true

module STQueue
  class Process # :nodoc:
    class << self
      def all
        STQueue.store.queues.map do |name, pid|
          process = Process.new(pid, name)
          unless process.running?
            STQueue.store.pop(name)
            next
          end
          process
        end.compact
      end

      def find_or_create_by(pid: nil, queue_name: nil)
        return if queue_name.blank? && pid.blank?
        find_by(pid: pid, queue_name: queue_name) || create(queue_name)
      end

      def find_by(pid: nil, queue_name: nil)
        return if queue_name.blank? && pid.blank?
        all.find do |process|
          (pid.present? && process.pid == pid) || (queue_name.present? && process.queue_name == queue_name)
        end
      end

      def create(queue_name)
        return if queue_name.blank?
        log_file_path = STQueue.log_dir.join("#{queue_name}.log")
        pid = `bundle exec sidekiq \
                -c #{STQueue.concurrency} \
                -q #{queue_name} \
                >> #{log_file_path} 2>&1 & \
                echo $!`.to_i
        STQueue.store.push(queue_name, pid)
        Sidekiq.logger.info("[STARTING] Sidekiq process for queue '#{queue_name}' with pid '#{pid}'")
        new(pid, queue_name)
      end
    end

    attr_reader :pid, :queue_name, :killed

    def initialize(pid, queue_name)
      @pid        = pid
      @queue_name = queue_name
      @killed     = false
    end

    def running?
      return false if killed
      `ps -ax -r -o pid`.split("\n").drop(1).map!(&:strip).include?(pid.to_s)
    end

    def kill
      return unless running?
      @killed = true
      system("kill #{pid}")
      STQueue.store.pop(queue_name)
      Sidekiq.logger.info("[STOPPING] Sidekiq process for queue '#{queue_name}' with pid '#{pid}'")
    end
  end
end
