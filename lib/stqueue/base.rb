# frozen_string_literal: true

module STQueue
  module Base # :nodoc:
    extend ActiveSupport::Concern

    included do
      after_perform do
        lock_info = Utils.lock_info(queue_name)
        until lock_info
          sleep 1
          lock_info = Utils.lock_info(queue_name)
        end
        process = STQueue::Process.find_by(queue_name: queue_name)
        process.decrease_busy
        STQueue.lock_manager.unlock(lock_info)
        if process&.need_to_kill?
          Sidekiq::Queue.new(queue_name).clear
          process.delete
        end
      end

      before_enqueue do
        STQueue::Process.find_by(queue_name: queue_name).increase_busy
      end
    end

    module ClassMethods # :nodoc:
      def separate_by(key: nil, concurrency: STQueue.concurrency)
        if STQueue.enabled && key.present? && concurrency.present?
          process = STQueue.monitor.separate_by(key, concurrency)
          queue_as process.queue_name
        end
        self
      end
    end
  end
end
