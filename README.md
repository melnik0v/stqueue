## Installation

Add this line to your application's Gemfile:

```ruby
  gem 'stqueue', github: 'jpmobiletanaka/stqueue'
```

And then execute:

    $ bundle install

Create an initializer at `config/initializers/stqueue.rb` and add
```ruby
  STQueue.configure do |config|
    config.enabled = true
    # log_dir should be a `Pathname`
    config.log_dir = Rails.root.join('stqueue')
    # store can be :file or :redis
    config.store = :file
    # or
    config.store = :redis
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

STQueue supports Ruby 2.2+, Rails. 4.1+, Sidekiq