# frozen_string_literal: true

module STQueue
  module Base # :nodoc:
    extend ActiveSupport::Concern

    included do
      after_perform do
        process = STQueue::Process.find_by(queue_name: queue_name)
        process.self_kill if process&.need_to_kill?
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
