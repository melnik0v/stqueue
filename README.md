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
    config.tmp_dir = Rails.root.join('tmp', 'pids') # for file store
  end
```

## Usage

Add
```ruby
  include STQueue::Base
```
to SomeJob

Run Jobs like:
```ruby
  SomeJob.separate_by(key: :some_uniq_key, concurrency: 5)...other_methods...perform_later(args)
  # or 
  SomeJob.separate_by(key: "some_uniq_key_#{model.id}", concurrency: 1)...other_methods...perform_later(args)
  # or
  SomeJob.separate_by(key: :some_uniq_key)...other_methods...perform_later(args)
  # or 
  SomeJob.separate_by(key: [model.id, model.name, Date.current])...other_methods...perform_later(args)
```

Also you can start and stop processes manually:
```ruby
  STQueue::Process.all           # => [#<STQueue::Process:0x00007f965217c1f0 @concurrency=10, @log_file_path...>, ...]
  STQueue::Process.first         # => #<STQueue::Process:0x00007f965217c1f0 @concurrency=10, @log_file_path...>
  STQueue::Process.first.kill    # killing the process and return same object with pid = nil
  STQueue::Process.first.start   # starting the process and return same object with pid
  STQueue::Process.first.restart # starting the process and return same object with updated pid
  STQueue::Process.find_by(name: queue_name)
```
## Result

`STQueue` started Sidekiq process for each unique `key`.
 - If some process stopped (but queue is not empty), `STQueue` will restart Sidekiq process and continue working
 - If queue is empty `STQueue` will stop the process

## Support

Tested for Ruby 2.3+, Rails. 5.0+, Sidekiq 4.0+
