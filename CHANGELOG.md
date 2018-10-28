## v.0.0.5 (2018-10-28)
 - Updated Bundler version from `1.16.2` to `1.16.4`
 - Removed health checks at every job launch
 - Added rake task `stqueue:check` for manually run health checks
 - Added method `stopped?` for `STQueue::Process`
 - After performing job can stop only related Sidekiq process
 - Added ability to use `Numeric` values as queue names
 - Added checking job retries before killing the Sidekiq process
 - Added checking `Sidekiq::ProcessSet`