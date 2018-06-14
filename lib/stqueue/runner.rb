module STQueue
  class Runner # :nodoc:
    QUEUE_PREFIX = :stqueued
    WRONG_KEY_ERROR = ':key attribute is incorrect'.freeze

    class << self
      def start(params = {})
        new(params).start
      end

      def stop(queue_name)
        pid = STQueue.monitor.pop(queue_name)
        `kill #{pid}`
      end
    end

    def initialize(params)
      @key_object     = params[:key]
      @queue_to_start = params[:queue_name]
    end

    def start
      return queue_name if STQueue.monitor.running?(queue_name)
      pid = run_and_get_pid
      raise Error, 'Cannot get PID of Sidekiq process' if pid.blank?
      STQueue.monitor.push(queue_name, pid)
      queue_name
    end

    private

    attr_reader :queue_to_start, :key_object

    def run_and_get_pid
      `$(which sidekiq) -c #{ENV['STQUEUE_THREADS'] || 1} -q #{queue_name} >> #{log_file_path} 2>&1 &
        echo $!`.to_i
    end

    def queue_name
      @_queue_name ||= queue_to_start || key.to_s
    end

    def key
      case key_object
      when Array
        key_object.map!(&:to_s).unshift(QUEUE_PREFIX).join('_')
      when String, Symbol
        [QUEUE_PREFIX, key_object.to_s].join('_')
      else
        raise Error, WRONG_KEY_ERROR
      end
    end

    def check_logs_dir
      return if Dir.exist?(STQueue.log_dir)
      FileUtils.mkdir(STQueue.log_dir)
    end

    def log_file_path
      check_logs_dir
      STQueue.log_dir.join("#{queue_name}.log")
    end
  end
end
