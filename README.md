[![Build Status](http://img.shields.io/travis/intellum/delayed_after_commit.svg?style=flat)](https://travis-ci.org/intellum/delayed_after_commit)

# DelayedAfterCommit

Exactly the same as after_commit, except it puts the job onto the Sidekiq queue.

Allows you to queue active record methods, after they have been created or updated.

Requires Sidekiq, and Rails >= 6.

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
  delayed_after_update :hi_ive_been_updated
  delayed_after_create :hi_im_new_around_here

  def hi_ive_been_updated
    puts "Hi - I've been updated"
  end

  def hi_im_new_around_here
    puts "Hi - I've just been created"
  end
end

```

### Notes

If you want to invoke the `delayed_after_update` callback only when an attribute has changed, you must check the attribute change with `#previous_changes`. Example:

```ruby
delayed_after_update :geolocate, if: :location_changed?
```

won't invoke `geolocate` even if `#location` has changed.

Instead you must do something like

```ruby
delayed_after_update :geolocate, if: :location_was_changed?

def location_was_changed?
  "location".in? previous_changes
end
```

This is necessary because the callback is run after the transaction is committed to the database.

## Roadmap

- Allow asyncronous callbacks on destroying objects

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/intellum/delayed_after_commit.

