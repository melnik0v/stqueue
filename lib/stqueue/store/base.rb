# frozen_string_literal: true

module STQueue
  module Store
    class Base # :nodoc:
      def initialize
        @queues = {}
      end

      def queues
        load
        @queues
      end

      def pid(queue_name)
        return if queue_name.blank?
        load
        queue = queues[queue_name.to_s]
        queue.fetch(:pid, nil)
      end

      def push(queue_name, pid, concurrency)
        return if queue_name.blank? || pid.blank?
        load
        queues[queue_name.to_s] = { pid: pid.to_i, concurrency: concurrency }
        dump
      end

      def pop(queue_name)
        return if queue_name.blank?
        load
        queue = @queues.delete(queue_name.to_s)
        dump
        return unless queue
        queue[:pid]
      end

      def null(queue_name)
        return if queue_name.blank?
        load
        queue = queues[queue_name.to_s]
        return unless queue
        @queues[queue_name.to_s][:pid] = nil
        dump
      end

      def replace(*args)
        push(*args)
      end

      private

      def from_json
        @queues = JSON.parse(yield)
      rescue JSON::ParserError, TypeError
        @queues = {}
      end
    end
  end
end
