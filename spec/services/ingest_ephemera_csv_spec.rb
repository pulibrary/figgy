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
                                     label: ["Chile"],
                                     member_of_vocabulary_id: areas.id)
  end

  describe IngestEphemeraCSV::FolderData do
    subject(:folder) { described_class.new(base_path: imgdir, change_set_persister: change_set_persister, **fields) }
    let(:fields) { table.first.to_h }
    let(:table) { CSV.read(mdata, headers: true, header_converters: :symbol) }
    let(:mdata) { Rails.root.join("spec", "fixtures", "files", "ephemera.csv") }
    let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "chile") }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
    let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }


    describe "#fields" do
      it "has fields" do
        expect(folder.fields[:date_created]).to eq("2019")
      end
    end

    describe "#files" do
      it "has an image path" do
        expect(folder.image_path).to eq(File.join(imgdir, "01"))
        expect(folder.files.first.original_filename).to eq("01.jpg")
      end
    end
  end

  describe "#ingest" do
    it "ingests the metadata" do
      output = service.ingest
      folder = output.first
      expect(folder).to be_kind_of EphemeraFolder
      expect(folder.creator).to eq ["Tomás Bravo Urízar"]
      expect(folder.date_created).to eq ["2019"]
      expect(folder.description).to eq ["November 29. Museo de Arte Contemporáneo (MAC), Parque Forestal, Santiago. Protest/performance \"Un violador en tu camino,\" created by Las Tesis."]

      geo_sub_id = folder.geo_subject.first.id
      qs = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      resource = qs.find_by(id: geo_sub_id)
      expect(resource).to be_an_instance_of(EphemeraTerm)
    end
  end

end
