# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraCSV do
  subject(:service) { described_class.new(project.title, mdata, imgdir, change_set_persister, logger) }
  let(:project) do
    FactoryBot.create(:ephemera_project,
                      title: "project_1",
                      id: Valkyrie::ID.new("project_number_1"))
  end
  let(:project2) do
    FactoryBot.create(:ephemera_project,
                      title: "project_2",
                      id: Valkyrie::ID.new("project_number_2"))
  end
  let(:mdata) { Rails.root.join("spec", "fixtures", "files", "ephemera.csv") }
  let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "chile") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    project2.title
    politics_and_government = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                               label: "Politics and government")

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Democracy",
                                     member_of_vocabulary_id: politics_and_government.id)

    languages = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                 label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Spanish"],
                                     code: ["es"],
                                     member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                             label: "LAE Geographic Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Chile"],
                                     member_of_vocabulary_id: areas.id)
  end

  describe "#ingest" do
    it "ingests the metadata" do
      output = service.ingest
      folder = output.first
      expect(folder).to be_kind_of EphemeraFolder
      expect(folder.creator).to eq ["Tomás Bravo Urízar"]
      expect(folder.date_created).to eq ["2019"]
      expect(folder.description.first).to eq "Un violador en tu camino"
      expect(folder.language.count).to eq(1)
      expect(folder.member_of_collection_ids.count).to eq(2)
    end
  end

  describe FolderData do
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
        expect(folder.files[1].original_filename).to eq("01.png")
        expect(folder.files[2].original_filename).to eq("01.tif")
      end
    end
  end
end
