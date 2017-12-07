module WithQueueAdapter
  def with_queue_adapter(new_adapter)
    around do |example|
      begin
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
