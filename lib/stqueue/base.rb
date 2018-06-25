# frozen_string_literal: true

module STQueue
  module Base # :nodoc:
    extend ActiveSupport::Concern

    included do
      after_perform { STQueue.monitor.kill_processes_with_empty_queues }
    end

    module ClassMethods # :nodoc:
      def separate_by(key: nil, concurrency: STQueue.concurrency)
        if STQueue.enabled && key.present?
          process = STQueue.monitor.separate_by(key, concurrency)
          queue_as process.queue_name
        end
        self
      end
    end
  end
end
