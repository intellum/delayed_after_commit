require "delayed_after_commit/version"

module DelayedAfterCommit
  extend ActiveSupport::Concern

  class_methods do
    def enqueue_delayed_method(method, id)
      # this is used as a generic method that is created to run asyncronously from within sidekiq
      # it finds the object, and runs the deferred method
      obj = self.find(id)
      obj.send(method)
    end

    def delayed_on_create(method)
      delayed_after_commit(method, on: :create)
    end

    def delayed_on_update(method)
      delayed_after_commit(method, on: :update)
    end

    protected
    def delayed_after_commit(method, on: nil)
      # this creates a method that runs `enqueue_delayed_method`
      # it then adds that method to the after_commit callback
      on ||= :update
      delayed_method_name = "delayed_after_#{on}_#{method}"
      define_method(delayed_method_name) do |m = method|
        self.class.delay.enqueue_delayed_method(m, self.id)
      end
      self.after_commit(delayed_method_name.to_sym, on: on)
    end
  end
end
