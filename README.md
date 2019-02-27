## Installation

Add this line to your application's Gemfile:

```ruby
  gem 'stqueue', github: 'melnik0v/stqueue'
```

And then execute:

    $ bundle install

Create an initializer at `config/initializers/stqueue.rb` and add
```ruby
  STQueue.configure do |config|
    config.enabled = true
    # default concurrency for all queues
    config.concurrency = ENV['STQUEUE_CONCURRENCY'] # default 1
    # log_dir should be a `Pathname`
    config.log_dir = Rails.root.join('log', 'stqueue')
    # store_type can be :file or :redis
    config.store_type = :redis
    config.redis_url = "redis://#{ENV['REDIS_URL']}/12" # default 'redis://localhost:6379/12'
    # or
    config.store_type = :file
    config.pids_dir = Rails.root.join('tmp', 'pids') # for file store
  end
```

## Usage

Add
```ruby
  include STQueue::Base
```
to `SomeJob`

Run Jobs like:
```ruby
  SomeJob.separate_by(key: :some_uniq_key, concurrency: 5).perform_later(args)
  # or 
  SomeJob.separate_by(key: "some_uniq_key_#{model.id}", concurrency: 1).perform_later(args)
  # or
  SomeJob.separate_by(key: :some_uniq_key).perform_later(args)
  # or 
  SomeJob.separate_by(key: [model.id, model.name, Date.current]).perform_later(args)
```

### Note:
STQueue will generate queue name using `:key` attribute and `stqueued_` prefix, e.g.:

`{ key: [19, 'option1', :smth_else] }` => `stqueued_19_option1_smth_else`

Also you can start and stop processes manually:
```ruby
  STQueue::Process.all     # return all processes
  STQueue::Process.running # return all running processes
  STQueue::Process.stopped # return all stopped processes
  process = STQueue::Process.find_by(queue_name: 'queue_name')
  process.running? # => true
  process.kill     # killing the process and return same object with pid = nil
  process.start    # starting the process and return same object with pid
  process.restart  # restarting the process and return same object with updated pid
  process.delete   # kill and delete the process and return nil
```

Run `rake stqueue:check` or `STQueue.monitor.health_check!` from code to manually stop processes with empty queues and restart processes with non-empty queues

## Result

`STQueue` started Sidekiq process for each unique `key`.

## Support

Tested for Ruby 2.3+, Rails. 5.0+, Sidekiq 4.0+
