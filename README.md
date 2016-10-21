[![Build Status](http://img.shields.io/travis/intellum/delayed_after_commit.svg?style=flat)](https://travis-ci.org/intellum/delayed_after_commit)

# DelayedAfterCommit

Exactly the same as after_commit, except it puts the job onto the Sidekiq queue.

Allows you to queue active record methods, after they have been created or updated.

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

```ruby

class User < ActiveRecord::Base
  include DelayedAfterCommit
  delayed_on_update :increment_number_of_updates
  delayed_on_create :calculate_number_of_letters_in_name
end

```

## Roadmap

- Allow asyncronous callbacks on destroying objects

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/intellum/delayed_after_commit.

