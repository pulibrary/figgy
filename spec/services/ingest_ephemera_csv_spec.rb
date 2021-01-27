# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraCSV do
  subject(:service) { described_class.new(project.id, mdata, imgdir, change_set_persister, logger) }
  let(:project) do
    FactoryBot.create_for_repository(:ephemera_project,
                                     title: "Moscow Ephemera",
                                     id: Valkyrie::ID.new("project_number_1"))
  end
  let(:collection) do
    FactoryBot.create_for_repository(:collection,
                                     title: "Princeton Slavic Collection")
  end
  let(:mdata) { Rails.root.join("spec", "fixtures", "files", "pudl0125.csv") }
  let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "pudl0125") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    collection
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

    areas2 = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                              label: "LAE Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sri Lanka"],
                                     member_of_vocabulary_id: areas2.id)
  end
  # rubocop:disable Metrics/LineLength
  context "ingest" do
    let(:output) { service.ingest }
    let(:folder) { output.first }
    let(:folder2) { output[1] }
    let(:qs) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

    it "ingests the rows as EphemeraFolders" do
      expect(output.count).to eq(2)
      expect(folder).to be_an EphemeraFolder
      expect(folder2).to be_an EphemeraFolder
    end

    it "assocates folders with the project" do
      expect(folder.cached_parent_id).to eq(project.id)
    end

    it "attaches metadata to the folders" do
      expect(folder.creator).to eq ["John Doe"]
      expect(folder.date_created).to eq ["2013"]
      expect(folder.language.count).to eq(1)
      expect(folder.barcode.first).to eq("10000000")
      expect(folder2.barcode.first).to eq("00000000")
      expect(folder2.page_count.first).to eq("20")
    end
  end

  describe FolderData do
    subject(:folder) { described_class.new(base_path: imgdir, change_set_persister: change_set_persister, **fields) }
    let(:fields) { table.first.to_h }
    let(:table) { CSV.read(mdata, headers: true, header_converters: :symbol) }
    let(:mdata) { Rails.root.join("spec", "fixtures", "files", "pudl0125.csv") }
    let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "pudl0125") }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
    let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:qs) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

    describe "#fields" do
      it "has fields" do
        expect(folder.fields[:folder_number]).to eq("001")
        expect(folder.fields[:date_created]).to eq("2013")
        expect(folder.fields[:subject]).to eq("Mayors--Elections;Political campaigns--History;Elections--History")
      end
    end
    # rubocop:enable Metrics/LineLength

    describe "#geographic_origin" do
      it "has a geographic origin" do
        expect(folder.geographic_origin).to be_a EphemeraTerm
      end
    end

    describe "#page_count" do
      it "defaults to the number of images" do
        expect(folder.page_count.first).to eq("1")
      end
    end

    describe "#subject" do
      it "has subjects" do
        expect(folder.subject.count).to eq(3)
      end
    end

    describe "#geographic_subject" do
      it "has a geographic_subjects" do
        expect(folder.geographic_subject.count).to eq(1)
      end
    end

    describe "#genre" do
      it "has a genre" do
        term = qs.find_by(id: folder.genre)
        expect(term).to be_an EphemeraTerm
        expect(term.label.first).to eq("Ephemera")
      end
    end

    describe "#files" do
      it "has an image path" do
        expect(folder.image_path).to eq(File.join(imgdir, "001"))
        originals = folder.files.collect(&:original_filename)
        expect(originals).to include("example.tif")
      end
    end
  end
end
