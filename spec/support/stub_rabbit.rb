RSpec.configure do |config|
  config.before(:each) do |ex|
    unless ex.metadata[:rabbit_stubbed]
      allow(Figgy).to receive(:messaging_client) do
        instance_double(MessagingClient, publish: true, amqp_url: "http://example.com")
      end

      allow_any_instance_of(CleanupDerivativesJob).to receive(:messenger) do
        rabbit = instance_double(EventGenerator)
        allow(rabbit).to receive(:derivatives_created)
        allow(rabbit).to receive(:derivatives_deleted)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        rabbit
      end

      allow_any_instance_of(CreateDerivativesJob).to receive(:messenger) do
        rabbit = instance_double(EventGenerator)
        allow(rabbit).to receive(:derivatives_created)
        allow(rabbit).to receive(:derivatives_deleted)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        rabbit
      end

      allow_any_instance_of(ChangeSetPersister::Basic).to receive(:messenger) do
        rabbit = instance_double(EventGenerator)
        allow(rabbit).to receive(:derivatives_created)
        allow(rabbit).to receive(:derivatives_deleted)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        rabbit
      end
    end
  end
end
