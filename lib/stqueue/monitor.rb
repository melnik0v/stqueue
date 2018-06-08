module STQueue
  class Monitor # :nodoc:
    WRONG_PID_FILE_TYPE_ERROR = 'STQueue pid_file must be a `Pathname`. Use `Rails.root.join(...)` to define it.'.freeze
    EMPTY_PID_FILE_ERROR      = 'You must to specify pid_file in config/initializers/stqueue.rb'.freeze

    def initialize
      @pids = {}
    end

    def set_file(pid_file)
      @pid_file = pid_file
      self
    end

    def load!
      pids_from_file.each do |queue_name, running_pid|
        unless pid_really_exists?(running_pid)
          Sidekiq::Queue.new(queue_name).size.positive? && STQueue::Runner.start(queue_name: queue_name)
          next
        end
        pids[queue_name.to_sym] = running_pid.to_i
      end
      pids_to_file
    end

    def save(queue_name, running_pid)
      pids[queue_name.to_sym] = running_pid.to_i
      pids_to_file
    end

    def stopped?(queue_name)
      !running? queue_name
    end

    def running?(queue_name)
      pid(queue_name).present?
    end

    def pid(queue_name)
      pids[queue_name.to_sym]
    end

    def similar(_queue_name)
      [] # TODO: implement feature
    end

    private

    attr_reader :pids, :pid_file

    def pid_really_exists?(running_pid)
      pid_list = `ps -o pid`.split("\n").drop(1).map!(&:strip)
      pid_list.include? running_pid.to_s
    end

    def pids_from_file
      raise Error, EMPTY_PID_FILE_ERROR      if pid_file.nil?
      raise Error, WRONG_PID_FILE_TYPE_ERROR unless pid_file.is_a? Pathname
      FileUtils.touch(pid_file) unless File.exist? pid_file
      content = File.read(pid_file)
      JSON.parse(content)
    rescue JSON::ParserError
      {}
    end

    def pids_to_file
      File.open(pid_file, 'w') { |f| f.write(pids.to_json) }
    end
  end
end
