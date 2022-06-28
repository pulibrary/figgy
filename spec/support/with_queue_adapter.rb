module WithQueueAdapter
  def with_queue_adapter(new_adapter)
    around do |example|
      begin
        # Rails 6 overrides ActiveJob queue_adapter. Need to disable the test adapter
        # See: https://github.com/rspec/rspec-rails/issues/2311
        (ActiveJob::Base.descendants << ActiveJob::Base).each(&:disable_test_adapter)
        old_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = new_adapter
        example.run
      ensure
        ActiveJob::Base.queue_adapter = old_adapter
      end
    end
  end
end


RSpec.configure do |config|
  config.extend WithQueueAdapter
end
