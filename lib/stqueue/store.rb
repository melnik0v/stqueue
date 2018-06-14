# frozen_string_literal: true

module STQueue
  module Store
    extend ActiveSupport::Concern

    included do
      def initialize
        @queues = {}
      end

      def queues
        load
        @queues
      end

      def pid(queue_name)
        load
        queues[queue_name.to_s]
      end

      def push(queue_name, pid)
        return if queue_name.blank? || pid.blank?
        load
        queues[queue_name.to_s] = pid.to_i
        dump
      end

      def pop(queue_name)
        return if queue_name.blank?
        load
        pid = @queues.delete(queue_name.to_s)
        dump
        pid
      end

      def load_from
        @queues = JSON.parse(yield)
      rescue JSON::ParserError, TypeError
        @queues = {}
      end
    end
  end
end
