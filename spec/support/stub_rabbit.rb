RSpec.configure do |config|
  config.before(:each) do |ex|
    unless ex.metadata[:rabbit_stubbed]
      allow(Figgy).to receive(:messaging_client) do
        instance_double(MessagingClient, publish: true)
      end

      allow_any_instance_of(PlumChangeSetPersister::Basic).to receive(:messenger) do
        rabbit = instance_double(ManifestEventGenerator)
        allow(rabbit).to receive(:record_created)
        allow(rabbit).to receive(:record_updated)
        allow(rabbit).to receive(:record_deleted)
        rabbit
      end
    end
  end
end
