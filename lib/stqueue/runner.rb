module STQueue
  class Runner # :nodoc:
    QUEUE_PREFIX = :stqueued

    class << self
      def start(params = {})
        new(params).start
      end

      def stop(queue_name)
        binding.pry
        return if STQueue.monitor.stopped? queue_name
        pid = STQueue.monitor.pid(queue_name)
        system("kill #{pid}")
      end
    end

    def initialize(params)
      @key = [QUEUE_PREFIX, params[:key].to_s].join('_')
      @key = params[:key].map!(&:to_s).unshift(QUEUE_PREFIX).join('_') if params[:key].is_a? Array
      @queue_to_start = params[:queue_name]
    end

    def start
      return queue_name if STQueue.monitor.running? queue_name
      kill_similar
      pid = Open4.popen4(command).first
      raise Error, 'Cannot get PID of Sidekiq process' if pid.blank?
      STQueue.monitor.save(queue_name, pid)
      queue_name
    end

    private

    attr_reader :key, :queue_to_start

    def kill_similar
      similar = STQueue.monitor.similar(queue_name)
      return if similar.blank?
      similar.each { |pid| system("kill #{pid}") }
    end

    def command
      "$(which sidekiq) -d -c #{ENV['STQUEUE_THREADS'] || 1} -q #{queue_name} -L #{log_file_path}"
    end

    def queue_name
      @_queue_name ||= queue_to_start || key.to_s
    end

    def check_logs_dir
      return if Dir.exist? STQueue.log_dir
      FileUtils.mkdir(STQueue.log_dir)
    end

    def log_file_path
      check_logs_dir
      STQueue.log_dir.join("#{queue_name}.log")
    end
  end
end
