[![Build Status](http://img.shields.io/travis/intellum/delayed_after_commit.svg?style=flat)](https://travis-ci.org/intellum/delayed_after_commit)

# DelayedAfterCommit

Exactly the same as after_commit, except it puts the job onto the Sidekiq queue.

Allows you to queue active record methods, after they have been created, updated, or destroyed.

Requires Sidekiq, and Rails >= 4.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_after_commit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_after_commit

## Usage

```

class User < ActiveRecord::Base
  include DelayedAfterCommit
  delayed_on_update :increment_number_of_updates
  delayed_on_create :calculate_number_of_letters_in_name
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/intellum/delayed_after_commit.

