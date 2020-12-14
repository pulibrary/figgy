# frozen_string_literal: true
require "rails_helper"

RSpec.describe AddEphemeraToCollectionJob do
  describe ".perform" do
    let(:service) { instance_double(AddEphemeraToCollection) }
    let(:project) do
      FactoryBot.create_for_repository(:ephemera_project,
                                       member_ids: box.id)
    end
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:box) do
      FactoryBot.create_for_repository(:ephemera_box,
                                       member_ids: folder.id)
    end
    let(:folder) { FactoryBot.create_for_repository(:complete_ephemera_folder) }

    before do
      allow(AddEphemeraToCollection).to receive(:new).and_return(service)
      allow(service).to receive(:add_ephemera)
    end
    it "Adds Ephemera to Collection" do
      described_class.perform_now(project.id, collection.id)
      expect(service).to have_received(:add_ephemera)
    end
  end
end
