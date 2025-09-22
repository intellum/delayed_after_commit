# frozen_string_literal: true

require "delayed_after_commit/version"
require "delayed_after_commit/worker"

module DelayedAfterCommit
  extend ActiveSupport::Concern

  class_methods do
    def delayed_after_create(*args, &block)
      args[1] ||= {}
      args[1][:on] = :create
      delayed_after_commit(*args, &block)
    end

    def delayed_after_update(*args, &block)
      args[1] ||= {}
      args[1][:on] = :update
      delayed_after_commit(*args, &block)
    end

    protected

    def delayed_after_commit(*args, &block)
      # this creates a method that runs `enqueue_delayed_method`
      # it then adds that method to the after_commit callback
      opts = args.extract_options!
      retry_max = opts.delete(:retry_max)
      queue = opts.delete(:queue) || 'default'

      method = args.first
      delayed_method_name = "delayed_after_#{opts[:on]}_#{method}"
      define_method(delayed_method_name) do |m = method|
        Worker.set(queue:).perform_async(self.class.name, m.to_s, id.to_s, retry_max.to_i, 0, queue.to_s)
      end
      after_commit(delayed_method_name.to_sym, opts, &block)
    end
  end
end
