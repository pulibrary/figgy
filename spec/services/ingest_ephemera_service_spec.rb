# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestEphemeraService, :admin_set do
  subject(:ingest_service) { described_class.new(folder, nil, project.title.first, change_set_persister, logger) }
  let(:folder) { Rails.root.join("spec", "fixtures", "lae_migration", "folders", "0003d") }
  let(:empty_folder) { Rails.root.join("spec", "fixtures", "lae_migration", "folders", "012g6") }
  let(:project) { FactoryBot.create_for_repository(:ephemera_project) }
  let(:logger) { Logger.new(nil) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:genres) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Genres") }
  let(:subjects) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Subjects") }
  let(:languages) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Languages") }
  let(:areas) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Areas") }
  let(:postcards) { FactoryBot.create_for_repository(:ephemera_term, label: "Postcards", member_of_vocabulary_id: genres.id) }
  let(:museums) { FactoryBot.create_for_repository(:ephemera_term, label: "Museums", member_of_vocabulary_id: subjects.id) }
  let(:spanish) { FactoryBot.create_for_repository(:ephemera_term, label: "Spanish", member_of_vocabulary_id: languages.id) }
  let(:wonderland) { FactoryBot.create_for_repository(:ephemera_term, label: "Wonderland", member_of_vocabulary_id: areas.id) }
  let(:argentina) { FactoryBot.create_for_repository(:ephemera_term, label: "Argentina", member_of_vocabulary_id: areas.id) }
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: metadata_adapter,
                           storage_adapter: storage_adapter)
  end
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  before do
    postcards
    museums
    spanish
    wonderland
    argentina
  end

  describe "#ingest" do
    context "with a valid folder" do
      let(:ingested) { query_service.find_all_of_model(model: EphemeraFolder).first }

      it "ingests an ephemera folder" do
        expect do
          change_set_persister.buffer_into_index do |buffered|
            described_class.new(folder, "complete", project.title.first, buffered, logger).ingest
          end
        end.to change { query_service.find_all_of_model(model: EphemeraFolder).to_a.length }.by(1)
        expect(ingested.title).to eq(["En negro y blanco. Del Cordobazo al juicio a las juntas."])
        expect(ingested.alternative_title).to eq ["Alternative"]
        expect(ingested.sort_title).to eq ["en negro y blanco. del cordobazo al juicio a las juntas."]
        expect(ingested.date_range.first.start.first).to eq "1993"
        expect(ingested.date_range.first.end.first).to eq "2004"
        expect(ingested.barcode).to eq ["32101093680013"]
        expect(ingested.description).to eq ["Test description"]
        expect(ingested.series).to eq ["Test Series"]
        expect(ingested.read_groups).to eq []
        expect(ingested.pdf_type).to eq ["none"]
        expect(ingested.member_ids.length).to eq 2
        expect(ingested.rights_statement).to eq [RightsStatements.copyright_not_evaluated]
        expect(ingested.state).to eq ["complete"]
        expect(ingested.local_identifier).to eq ["0003d"]
        expect(ingested.folder_number).to eq ["2"]
        expect(ingested.height).to eq ["11"]
        expect(ingested.width).to eq ["16"]
        expect(ingested.page_count).to eq ["2"]

        members = query_service.find_members(resource: ingested).to_a

        expect(members.first.title).to eq ["1"]
        expect(members.last.title).to eq ["2"]

        expect(ingested.genre.first).to eq postcards.id
        expect(ingested.genre.first).to be_kind_of(Valkyrie::ID)
        expect(ingested.subject).to contain_exactly museums.id, "Not Found"
        expect(ingested.language.first).to eq(spanish.id)
        expect(ingested.language.first).to be_kind_of(Valkyrie::ID)
        expect(ingested.geo_subject.first).to eq(wonderland.id)
        expect(ingested.geo_subject.first).to be_kind_of(Valkyrie::ID)
        expect(ingested.geographic_origin.first).to eq(argentina.id)
        expect(ingested.geographic_origin.first).to be_kind_of(Valkyrie::ID)
        expect(ingested.state.first).to eq "complete"

        box = query_service.find_parents(resource: ingested).to_a.first

        expect(box).to be_a EphemeraBox
        expect(box.local_identifier).to eq ["00014"]
        expect(box.barcode).to eq ["32101081556985"]
        expect(box.box_number).to eq ["1"]
        expect(box.tracking_number).to eq ["1Z0803280352213599"]
        expect(box.shipped_date).to eq ["2014-04-08"]
        expect(box.received_date).to eq ["2014-05-12"]
        expect(box.state).to eq ["received"]

        found_project = query_service.find_parents(resource: box).to_a.first
        expect(found_project.id).to eq project.id
      end

      it "can ingest via a job" do
        IngestEphemeraJob.perform_now(folder, nil, project.title.first)
        expect(ingested.title).to eq ["En negro y blanco. Del Cordobazo al juicio a las juntas."]
      end
    end

    context "with a valid folder with no attached images" do
      let(:ingested) { query_service.find_all_of_model(model: EphemeraFolder).first }

      it "ingests an ephemera folder" do
        expect do
          change_set_persister.buffer_into_index do |buffered|
            described_class.new(empty_folder, "complete", project.title.first, buffered, logger).ingest
          end
        end.to change { query_service.find_all_of_model(model: EphemeraFolder).to_a.length }.by(1)
        expect(ingested.title).to eq(["Se firmó el convenio para terminar el Edificio Único de Sociales. El cambio se hace desde abajo: La Vallese."])
        expect(ingested.barcode).to eq ["32101089002131"]
        expect(ingested.member_ids.length).to eq 0
        expect(ingested.rights_statement).to eq [RightsStatements.copyright_not_evaluated]
        expect(ingested.state).to eq ["complete"]
        expect(ingested.local_identifier).to eq ["012g6"]
        expect(ingested.folder_number).to eq ["7"]
        expect(ingested.page_count).to eq ["1"]

        members = query_service.find_members(resource: ingested).to_a
        expect(members).to eq []
      end
    end

    context "when the folder doesn't exist" do
      let(:folder) { Rails.root.join("spec", "fixtures", "bogus") }
      let(:logger) { instance_double(Logger) }

      before do
        allow(logger).to receive(:warn)
      end

      it "logs an error" do
        expect { ingest_service.ingest }.not_to change { query_service.find_all_of_model(model: EphemeraFolder).to_a.length }
        expect(logger).to have_received(:warn).with("Error: No such file or directory @ rb_sysopen - #{folder}/foxml")
      end
    end
  end

  describe "state" do
    let(:box) { FactoryBot.build(:ephemera_box) }
    let(:box_prov) { File.new Rails.root.join("spec", "fixtures", "lae_migration", "boxes", "00014", "provMetadata") }
    let(:folder) { FactoryBot.build(:ephemera_folder) }
    let(:folder_prov1) { File.new Rails.root.join("spec", "fixtures", "lae_migration", "folders", "0003d", "provMetadata") }
    let(:folder_prov2) { File.new Rails.root.join("spec", "fixtures", "lae_migration", "folders", "012g6", "provMetadata") }
    it "parses the state for a box" do
      expect(IngestEphemeraService::ProvMetadata.new(box_prov, box).state).to eq "received"
    end
    it "maps 'in production' folders to 'complete'" do
      expect(IngestEphemeraService::ProvMetadata.new(folder_prov1, folder).state).to eq "complete"
    end
    it "maps other folder states to 'needs_qa'" do
      expect(IngestEphemeraService::ProvMetadata.new(folder_prov2, folder).state).to eq "needs_qa"
    end
  end
end
