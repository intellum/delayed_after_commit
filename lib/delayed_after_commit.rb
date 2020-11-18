require "delayed_after_commit/version"

module DelayedAfterCommit
  extend ActiveSupport::Concern

  class_methods do
    # If retry_max is set, the queued method will retry that number of times
    # before finally failing. retry_count is automatically incremented with
    # each run of the method.
    def enqueue_delayed_method(method, id, retry_max = nil, retry_count = 0)
      # this is used as a generic method that is created to run asyncronously from within sidekiq
      # it finds the object, and runs the deferred method
      begin
        if obj = self.find_by_id(id)
          obj.send(method)
        end
      rescue => e
        if retry_max.present? && retry_count < retry_max
          self.delay_for(retry_count * 60, retry: false).enqueue_delayed_method(method, id, retry_max, retry_count + 1)
        end

        raise e
      end
    end

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
      method = args.first
      delayed_method_name = "delayed_after_#{opts[:on]}_#{method}"
      define_method(delayed_method_name) do |m = method|
        if retry_max.present?
          self.class.delay(retry: false).enqueue_delayed_method(m, self.id, retry_max)
        else
          self.class.delay.enqueue_delayed_method(m, self.id)
        end
      end
      self.after_commit(delayed_method_name.to_sym, opts, &block)
    end
  end
end
