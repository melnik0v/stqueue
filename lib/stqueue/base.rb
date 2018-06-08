module STQueue
  class Base # :nodoc:
    class << self
      def setup!
        ActiveJob::Base.instance_eval do
          def separate_by(params)
            queue_name = STQueue::Runner.start(params)
            STQueue::Base.set_after_perform_callback(self, queue_name)
            self
          end
        end
      end

      def set_after_perform_callback(klass, queue_name)
        klass.class_eval do
          queue_as queue_name.to_sym

          after_perform do |job|
            return if Sidekiq::Queue.new(job.queue_name).size > 1
            STQueue::Runner.stop(queue_name)
          end
        end
      end
    end
  end
end
