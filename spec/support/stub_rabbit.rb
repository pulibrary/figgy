RSpec.configure do |config|
  config.before(:each) do |ex|
    unless ex.metadata[:rabbit_stubbed]
      allow(Figgy).to receive(:messaging_client) do
        instance_double(MessagingClient, bunny_client: double("Bunny Client"), publish: true, amqp_url: "http://example.com")
      end

      allow_any_instance_of(CreateDerivativesJob).to receive(:messenger) do
        rabbit = instance_double(EventGenerator)
        allow(rabbit).to receive(:derivatives_created)
        allow(rabbit).to receive(:derivatives_deleted)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        allow(rabbit).to receive(:record_member_updated)
        rabbit
      end

      allow_any_instance_of(ChangeSetPersister::Basic).to receive(:messenger) do
        rabbit = instance_double(EventGenerator)
        allow(rabbit).to receive(:derivatives_created)
        allow(rabbit).to receive(:derivatives_deleted)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        allow(rabbit).to receive(:record_member_updated)
        rabbit
      end
    else
      # silence bunny logging
      logger = instance_double(Logger)
      allow(logger).to receive(:warn)
      allow_any_instance_of(Bunny::Session).to receive(:init_default_logger).and_return(logger)
    end
  end
end
