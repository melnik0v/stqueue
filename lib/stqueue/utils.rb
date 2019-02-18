# frozen_string_literal: true

module STQueue
  class Utils # :nodoc:

    class << self
      def generate_queue_name(key)
        case key
        when Array
          key.map!(&:to_s).unshift(STQueue::QUEUE_PREFIX).join('_')
        when String, Symbol, Numeric
          [STQueue::QUEUE_PREFIX, key.to_s].join('_')
        else
          raise Error, WRONG_KEY_ERROR
        end
      end

      def lock_info(queue_name)
        STQueue.lock_manager.lock(lock_queue_name(queue_name), DEFAULT_TTL)
      end

      private

      def lock_queue_name(queue_name)
        [STQueue::REDLOCK_PREFIX, queue_name].join('_')
      end
    end
  end
end
