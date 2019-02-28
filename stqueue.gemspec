# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "English"
require "stqueue/version"

Gem::Specification.new do |gem|
  gem.name          = "stqueue"
  gem.version       = STQueue::VERSION
  gem.authors       = ["Alexey Melnikov"]
  gem.email         = ["alexbeat96@gmail.com"]

  gem.summary       = 'Separate Threaded Queues for Sidekiq Jobs'
  gem.description   = 'Separate Threaded Queues for Sidekiq Jobs'
  gem.homepage      = "https://github.com/jpmobiletanaka/stqueue"
  gem.license       = "MIT"
  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)

  gem.required_ruby_version = '>= 2.2'
  gem.require_paths = %w(lib)
end
