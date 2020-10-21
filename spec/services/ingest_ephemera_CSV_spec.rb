# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraCSV do
  subject(:service) { described_class.new(project.id, mdata, imgdir, change_set_persister, logger) }
  let(:project) { FactoryBot.create(:ephemera_project) }
  let(:mdata) { Rails.root.join("spec", "fixtures", "files", "ephemera.csv") }
  let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "chile") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    languages = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                 label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Spanish"],
                                     code: ["es"],
                                     member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                             label: "LAE Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Ukraine"],
                                     member_of_vocabulary_id: areas.id)
  end

  describe "#ingest" do
    it "ingests the metadata" do
      output = service.ingest
      expect(output).to be_kind_of EphemeraFolder
      expect(output.creator).to eq ["Tomás Bravo Urízar"]
      expect(output.date_created).to eq [2019]
      expect(output.geo_subject).to eq ["Chile"]
      expect(output.description).to eq ["November 29. Museo de Arte Contemporáneo (MAC), Parque Forestal, Santiago. Protest/performance \"Un violador en tu camino,\" created by Las Tesis."]
    end
  end

end
