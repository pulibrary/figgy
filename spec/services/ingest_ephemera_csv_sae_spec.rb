# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraCSV do
  subject(:service) { described_class.new([project.id, project2.id], mdata, imgdir, change_set_persister, logger) }
  let(:project) do
    FactoryBot.create(:ephemera_project,
                      title: "South Asian Ephemera",
                      id: Valkyrie::ID.new("project_number_1"))
  end
  let(:project2) do
    FactoryBot.create(:ephemera_project,
                      title: "Dissidents and Activists in Sri Lanka, 1960s to 1990",
                      id: Valkyrie::ID.new("project_number_2"))
  end
  let(:mdata) { Rails.root.join("spec", "fixtures", "files", "sae_ephemera.csv") }
  let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "sae") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    project2.title
    project2.id
    politics_and_government = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                               label: "Politics and government")

    human_and_civil_rights = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                              label: "Human and civil rights")

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Human rights advocacy",
                                     member_of_vocabulary_id: human_and_civil_rights.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Civil Rights",
                                     member_of_vocabulary_id: human_and_civil_rights.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Constitutions",
                                     member_of_vocabulary_id: politics_and_government.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Politics and government",
                                     member_of_vocabulary_id: politics_and_government.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Decentralization in government",
                                     member_of_vocabulary_id: politics_and_government.id)

    languages = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                 label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sinhala | Sinhalese"],
                                     code: ["sin"],
                                     member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                             label: "LAE Geographic Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sri Lanka"],
                                     member_of_vocabulary_id: areas.id)
  end
  # rubocop:disable Metrics/LineLength
  context "ingest" do
    let(:output) { service.ingest }
    let(:qs) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

    it "ingests the both rows to both projects" do
      expect(output.count).to eq(2)
      expect(output.first.count).to eq(2)
      expect(output[1].count).to eq(2)
    end

    it "ingests the rows as EphemeraFolders" do
      project = qs.find_by(id: output.first.first)
      expect(project).to be_an EphemeraProject
      expect(project.member_ids.count).to eq(2)
      folder = qs.find_by(id: project.member_ids.first)
      expect(folder).to be_an EphemeraFolder
      folder = qs.find_by(id: project.member_ids[1])
      expect(folder).to be_an EphemeraFolder
    end

    it "attaches metadata to the folders" do
      project = qs.find_by(id: output.first.first)
      folder = qs.find_by(id: project.member_ids.first)
      expect(folder.creator).to eq ["Movement for Inter Racial Justice and Equality (MIRJE)"]
      expect(folder.date_created).to eq ["Circa 1986"]
      expect(folder.description.first).to eq "Contributor-provided translation of title:  Reccomendations of the Movement for Inter Racial Justice and Equality (MIRJE)for the completion of Provincial Council recommendations  ; Left wing political pamphlets"
      expect(folder.language.count).to eq(1)
      expect(folder.member_of_collection_ids.count).to eq(2)
      expect(qs.find_by(id: folder.geo_subject.first.id)).to be_an EphemeraTerm
    end
  end

  describe FolderData do
    subject(:folder) { described_class.new(base_path: imgdir, change_set_persister: change_set_persister, **fields) }
    let(:fields) { table.first.to_h }
    let(:table) { CSV.read(mdata, headers: true, header_converters: :symbol) }
    let(:mdata) { Rails.root.join("spec", "fixtures", "files", "sae_ephemera.csv") }
    let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "sae") }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
    let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:qs) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

    describe "#fields" do
      it "has fields" do
        expect(folder.fields[:date_created]).to eq("Circa 1986")
        expect(folder.fields[:subject]).to eq("Politics and government--Constitutions/Politics and government--Politics and government/Politics and government--Decentralization in government/Human and civil rights--Human rights advocacy/Human and civil rights--Civil Rights")
      end
    end
    # rubocop:enable Metrics/LineLength

    describe "#keywords" do
      it "has keywords" do
        expect(folder.keywords).to include("Movement of Inter Racial Justice and Equality")
      end
    end

    describe "#subject" do
      it "has subjects" do
        expect(folder.subject.count).to eq(5)
        expect(qs.find_by(id: folder.geo_subject.first.id)).to be_an EphemeraTerm
      end
    end

    describe "#files" do
      it "has an image path" do
        expect(folder.image_path).to eq(File.join(imgdir, "pamphlet0001"))
        originals = folder.files.collect(&:original_filename)
        expect(originals).to include("00000001.TIF")
        expect(originals).to include("00000002.tif")
        expect(originals).to include("00000003.jpg")
        expect(originals).to include("00000004.png")
      end
    end
  end
end
