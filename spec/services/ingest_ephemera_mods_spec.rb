# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraMODS do
  subject(:service) { described_class.new(project.id, mods, dir, change_set_persister, logger) }
  let(:project) { FactoryBot.create(:ephemera_project) }
  let(:mods) { Rails.root.join("spec", "fixtures", "files", "ukrainian-001.mods") }
  let(:dir) { Rails.root.join("spec", "fixtures", "files", "raster") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    languages = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term, label: ["Russian"], code: ["rus"], member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Areas")
    FactoryBot.create_for_repository(:ephemera_term, label: ["Ukraine"], member_of_vocabulary_id: areas.id)
  end

  describe "#ingest" do
    it "ingests the MODS file and TIFFs" do
      output = service.ingest
      expect(output).to be_kind_of EphemeraFolder
      expect(output.date_created).to eq ["2014"]
      expect(output.decorate.language.first.label).to eq "Russian"
      expect(output.member_ids.length).to eq 1
    end
  end

  context "Ukrainian ephemera" do
    subject(:service) { IngestEphemeraMODS::IngestUkrainianEphemeraMODS.new(project.id, mods, dir, change_set_persister, logger) }

    it "ingests the MODS file and TIFFs with metadata overrides" do
      output = service.ingest
      expect(output).to be_kind_of EphemeraFolder
      expect(output.date_created).to eq ["2014"]
      expect(output.decorate.language.first.label).to eq "Russian"
      expect(output.decorate.geo_subject.first.label).to eq "Ukraine"
      expect(output.decorate.geographic_origin.label).to eq "Ukraine"
      expect(output.decorate.subject).to include "Protest movements"
      expect(output.member_ids.length).to eq 1
    end
  end
end
