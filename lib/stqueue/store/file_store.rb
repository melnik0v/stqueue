module STQueue
  module Store
    class FileStore < Base # :nodoc:
      def initialize
        super
        FileUtils.touch(pids_file) unless File.exist?(pids_file)
      end

      private

      def load
        load_from { File.read(pids_file) }
      end

      def dump
        File.open(pids_file, 'w') { |f| f.write(@queues.to_h.to_json) }
      end

      def pids_file
        Rails.root.join('tmp', 'pids', 'stqueue.pids')
      end
    end
  end
end
