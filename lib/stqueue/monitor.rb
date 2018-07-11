# frozen_string_literal: true

module STQueue
  class Monitor # :nodoc:
    WRONG_KEY_ERROR = ':key attribute is incorrect'

    def health_check!
      return unless STQueue.enabled
      kill_processes_with_empty_queues
      start_processes_with_non_empty_queues
    end

    def separate_by(key, concurrency)
      return unless STQueue.enabled
      queue_name = generate_queue_name(key)
      process = Process.find_or_initialize_by(queue_name: queue_name)
      return process.start if process.concurrency == concurrency
      process.set(:concurrency, concurrency).restart
    end

    def kill_processes_with_empty_queues
      return unless STQueue.enabled
      stqueues.each do |queue|
        next if queue.size.positive?
        process = Process.find_by(queue_name: queue.name)
        process.kill if process&.running?
      end
    end

    def start_processes_with_non_empty_queues
      return unless STQueue.enabled
      stqueues.each do |queue|
        next if queue.size.zero?
        Process.find_or_initialize_by(queue_name: queue.name).start
      end
    end

    def generate_queue_name(key)
      case key
      when Array
        key.map!(&:to_s).unshift(STQueue::QUEUE_PREFIX).join('_')
      when String, Symbol
        [STQueue::QUEUE_PREFIX, key.to_s].join('_')
      else
        raise Error, WRONG_KEY_ERROR
      end
    end

    private

    def stqueues
      Sidekiq::Queue.all.select { |q| q.name.match?(STQueue::QUEUE_PREFIX) }
    end
  end
end
