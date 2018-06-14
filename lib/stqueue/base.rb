module STQueue
  module Base # :nodoc:
    extend ActiveSupport::Concern

    included do
      after_perform { STQueue.monitor.stop_empty if STQueue.enabled }
    end

    module ClassMethods # :nodoc:
      def separate_by(params)
        if STQueue.enabled
          queue_name = STQueue::Runner.start(params)
          queue_as queue_name.to_sym
        end
        self
      end
    end
  end
end
