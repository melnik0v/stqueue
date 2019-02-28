# frozen_string_literal: true

module STQueue
  class Monitor # :nodoc:
    WRONG_KEY_ERROR = ':key attribute is incorrect'

    def health_check!
      return unless STQueue.enabled
      stqueues.each do |queue|
        process = Process.find_or_initialize_by(queue_name: queue.name)
        process.kill if process.need_to_kill?
      end
    end

    def clear_store!
      return unless STQueue.enabled
      STQueue::Process.all.each(&:delete)
    end

    def stop_processes!
      return unless STQueue.enabled
      STQueue::Process.all.select(&:need_to_kill?).each(&:delete)
    end

    def separate_by(key, concurrency)
      return unless STQueue.enabled
      queue_name = Utils.generate_queue_name(key)
      process = Process.find_or_initialize_by(queue_name: queue_name)
      return process.start if process.concurrency == concurrency
      process.set(:concurrency, concurrency).restart
    end

    private

    def stqueues
      Sidekiq::Queue.all.select { |q| q.name.match?(STQueue::QUEUE_PREFIX) }
    end
  end
end
