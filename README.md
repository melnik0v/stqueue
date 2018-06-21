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
    config.concurrency = ENV['STQUEUE_CONCURRENCY'] || 1 # default 1
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

Run Jobs like
```ruby
  SomeJob.separate_by(key: :some_uniq_key)...other_methods...perform_later(args)
  # or 
  SomeJob.separate_by(key: "some_uniq_key_#{model.id}")...other_methods...perform_later(args)
  # or 
  SomeJob.separate_by(key: [model.id, model.name, Date.current])...other_methods...perform_later(args)
```

## Result

`STQueue` started Sidekiq process for each unique `key`.
 - If some process stopped (but queue is not empty), `STQueue` will restart Sidekiq process and continue working
 - If queue is empty `STQueue` will stop the process

## Support

Tested for Ruby 2.3+, Rails. 5.0+, Sidekiq 4.0+
