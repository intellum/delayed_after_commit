# frozen_string_literal: true

module DelayedAfterCommit
  # This is the worker that runs the delayed methods after a record is created or updated
  class Worker
    include Sidekiq::Job

    sidekiq_options retry: false

    def perform(class_name, method, id, retry_max = nil, retry_count = 0, queue = 'default')
      klass = class_name.constantize
      obj = klass.find_by(id:)
      begin
        obj.send(method) if obj.present?
      rescue StandardError => e
        if retry_max.present? && retry_count < retry_max
          self.class.set(queue:).perform_in(retry_count.minutes, class_name, method, id, retry_max, retry_count + 1, queue.to_s)
        end
        raise e
      end
    end
  end
end
