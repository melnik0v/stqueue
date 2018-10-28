module STQueue
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/stqueue.rake'
    end
  end
end