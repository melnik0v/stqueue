namespace :stqueue do
  desc 'Check health of running or stopped Sidekiq processes'
  task :check do
    STQueue.monitor.health_check!
  end

  desc 'Stop Sidekiq process'
  task :stop, :queue_name do |task, arg|
    return if arg[:queue_name].blank?
    process = STQueue::Process.find_by(queue_name: arg[:queue_name])
    return if process.blank?
    process.kill if process.need_to_kill?
  end
end