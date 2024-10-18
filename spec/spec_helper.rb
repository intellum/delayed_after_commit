# frozen_string_literal: true

require "rubygems"
require "bundler"
require "rspec"
require "active_record"
require 'sidekiq/testing'
require "delayed_after_commit"
require 'byebug'

Sidekiq::Testing.fake!

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define version: 0 do
  create_table(:users) do |t|
    t.string :name
    t.integer :number_of_updates
    t.integer :number_of_letters_in_name
  end
end

class User < ActiveRecord::Base
  include DelayedAfterCommit
  attr_accessor :increment_enabled, :fail_enabled

  delayed_after_update :increment_number_of_updates, if: :increment_enabled
  delayed_after_create :calculate_number_of_letters_in_name

  delayed_after_update :failing_callback, if: :fail_enabled, retry_max: 3

  protected

  def calculate_number_of_letters_in_name
    update_column('number_of_letters_in_name', name.size)
  end

  def increment_number_of_updates
    update_column('number_of_updates', number_of_updates.to_i + 1)
  end

  def failing_callback
    increment_number_of_updates
    raise "This fails"
  end
end
