# frozen_string_literal: true

module STQueue
  class Monitor # :nodoc:
    WRONG_KEY_ERROR = ':key attribute is incorrect'

    def health_check!
      kill_processes_with_empty_queues
      start_processes_with_non_empty_queues
    end

    def separate_by(key, concurrency)
      start_processes_with_non_empty_queues
      queue_name = generate_queue_name(key)
      process = Process.find_or_initialize_by(queue_name: queue_name)
      process.set(:concurrency, concurrency)
      process.start
      process.queue_name
    end

    def kill_processes_with_empty_queues
      return unless STQueue.enabled
      stqueues.each do |queue|
        next if queue.size.positive?
        process = Process.find_by(queue_name: queue.name)
        next unless process&.running?
        process.kill
      end
    end

    def start_processes_with_non_empty_queues
      return unless STQueue.enabled
      stqueues.each do |queue|
        next if queue.size.zero?
        process = Process.find_by(queue_name: queue.name)
        process.present? ? process.start : Process.create(queue.name)
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
