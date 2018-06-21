# frozen_string_literal: true

module STQueue
  module Store
    class RedisStore < Base # :nodoc:
      CONNECT_KEY = :stqueue_redis_store

      def initialize
        super
        @client = Redis.new(url: STQueue.redis_url)
      end

      private

      attr_reader :client

      def load
        from_json { client.get(CONNECT_KEY) }
      end

      def dump
        client.set(CONNECT_KEY, @queues.to_h.to_json)
      end
    end
  end
end
