module STQueue
  module Store
    class RedisStore # :nodoc:
      include STQueue::Store

      CONNECT_KEY = :stqueue_redis_store

      def initialize
        super
        @client = Redis.new
      end

      private

      attr_reader :client

      def load
        load_from { client.get(CONNECT_KEY) }
      end

      def dump
        client.set(CONNECT_KEY, @queues.to_h.to_json)
      end
    end
  end
end
