module STQueue
  class Monitor # :nodoc:
    delegate :pid, :push, :pop, to: :store

    def initialize
      @store = STQueue.store.new
    end

    def health_check
      restart_stopped
      check_running
      stop_empty
    end

    def stopped?(queue_name)
      !running?(queue_name)
    end

    def running?(queue_name)
      check_running
      pid(queue_name).present?
    end

    def stop_empty
      store.queues.each do |queue_name, running_pid|
        size = Sidekiq::Queue.new(queue_name).size
        next if size.positive? || !pid_really_exists?(running_pid)
        STQueue::Runner.stop(queue_name)
      end
    end

    def restart_stopped
      store.queues.each do |queue_name, running_pid|
        size = Sidekiq::Queue.new(queue_name).size
        next if size.zero? || pid_really_exists?(running_pid)
        STQueue::Runner.start(queue_name: queue_name)
      end
    end

    private

    attr_reader :store

    def check_running
      store.queues.each do |queue_name, running_pid|
        next if pid_really_exists? running_pid
        pop(queue_name)
      end
    end

    def pid_really_exists?(running_pid)
      pid_list = `ps -o pid`.split("\n").drop(1).map!(&:strip)
      pid_list.include? running_pid.to_s
    end
  end
end
