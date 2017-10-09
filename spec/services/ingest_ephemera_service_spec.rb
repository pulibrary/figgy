# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IngestEphemeraService, :admin_set do
  subject(:ingest_service) { described_class.new(folder, nil, project.title.first, change_set_persister, logger) }
  let(:folder) { Rails.root.join('spec', 'fixtures', 'lae_migration', 'folders', '0003d') }
  let(:project) { FactoryGirl.create_for_repository(:ephemera_project) }
  let(:logger) { Logger.new(nil) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:genres) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'LAE Genres') }
  let(:subjects) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'LAE Subjects') }
  let(:languages) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'LAE Languages') }
  let(:areas) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'LAE Areas') }
  let(:postcards) { FactoryGirl.create_for_repository(:ephemera_term, label: "Postcards", member_of_vocabulary_id: genres.id) }
  let(:museums) { FactoryGirl.create_for_repository(:ephemera_term, label: "Museums", member_of_vocabulary_id: subjects.id) }
  let(:spanish) { FactoryGirl.create_for_repository(:ephemera_term, label: "Spanish", member_of_vocabulary_id: languages.id) }
  let(:wonderland) { FactoryGirl.create_for_repository(:ephemera_term, label: "Wonderland", member_of_vocabulary_id: areas.id) }
  let(:change_set_persister) do
    PlumChangeSetPersister.new(metadata_adapter: metadata_adapter,
                               storage_adapter: storage_adapter)
  end
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:lae_storage) }
  before do
    postcards
    museums
    spanish
    wonderland
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
        expect(ingested.read_groups).to eq []
        expect(ingested.pdf_type).to eq ["none"]
        expect(ingested.member_ids.length).to eq 2
        expect(ingested.rights_statement).to eq [RDF::URI('http://rightsstatements.org/vocab/CNE/1.0/')]
        expect(ingested.state).to eq ["complete"]
        expect(ingested.local_identifier).to eq ['0003d']
        expect(ingested.folder_number).to eq ['2']
        expect(ingested.height).to eq ['11']
        expect(ingested.width).to eq ['16']

        members = query_service.find_members(resource: ingested).to_a

        expect(members.first.title).to eq ["1"]
        expect(members.last.title).to eq ["2"]

        expect(ingested.genre.first).to eq postcards.id
        expect(ingested.subject).to contain_exactly museums.id, "Not Found"
        expect(ingested.language.first).to eq(spanish.id)
        expect(ingested.geo_subject.first).to eq(wonderland.id)
        expect(ingested.state.first).to eq "complete"

        box = query_service.find_parents(resource: ingested).to_a.first

        expect(box).to be_a EphemeraBox
        expect(box.local_identifier).to eq ["00014"]
        expect(box.barcode).to eq ["32101081556985"]
        expect(box.box_number).to eq ["1"]

        found_project = query_service.find_parents(resource: box).to_a.first
        expect(found_project.id).to eq project.id
      end

      it "can ingest via a job" do
        IngestEphemeraJob.perform_now(folder, nil, project.title.first)
        expect(ingested.title).to eq ["En negro y blanco. Del Cordobazo al juicio a las juntas."]
      end
    end

    context "when the folder doesn't exist" do
      let(:folder) { Rails.root.join('spec', 'fixtures', 'bogus') }
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
end
