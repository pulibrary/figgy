# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateDaoJob do
  describe ".perform" do
    let(:updater) { instance_double("DaoUpdater") }

    it "calls DaoUpdater#update!" do
      resource = FactoryBot.create_for_repository(:complete_open_scanned_resource)
      allow(DaoUpdater).to receive(:new).and_return(updater)
      allow(updater).to receive(:update!)
      described_class.perform_now(resource.id)
      expect(updater).to have_received(:update!)
    end

    it "rescues and does not re-raise the ObjectNotFoundError for deleted objects" do
      expect do
        described_class.perform_now("deletedid")
      end.not_to raise_error
    end
  end
end
