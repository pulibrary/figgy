# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraMODS do
  subject(:service) { described_class.new(project.id, mods, dir, change_set_persister, logger) }
  let(:project) { FactoryBot.create(:ephemera_project) }
  let(:mods) { Rails.root.join("spec", "fixtures", "files", "ukrainian-001.mods") }
  let(:mods74) { Rails.root.join("spec", "fixtures", "files", "ukrainian-074.mods") }
  let(:dir) { Rails.root.join("spec", "fixtures", "lae", "32101075851418") }
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
      expect(output.member_ids.length).to eq 3
      expect(output.decorate.members.map(&:title).flatten).to eq ["0001.tif", "0002.tif", "ukrainian-001.mods"]
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
      expect(output.member_ids.length).to eq 3
    end
  end

  context "Ukrainian ephemera without native script title" do
    subject(:service) { IngestEphemeraMODS::IngestUkrainianEphemeraMODS.new(project.id, mods74, dir, change_set_persister, logger) }

    it "ingests MODS file without native script title" do
      output = service.ingest
      expect(output).to be_kind_of EphemeraFolder
      expect(output.title.map(&:to_s)).to eq ["I love UA"]
    end
  end

  context "GNIB ephemera" do
    subject(:service) { IngestEphemeraMODS::IngestGNIBMODS.new(project.id, mods, dir, change_set_persister, logger) }
    let(:mods) { Rails.root.join("spec", "fixtures", "files", "GNIB", "00223.mods") }
    let(:dir) { Rails.root.join("spec", "fixtures", "GNIB", "00223") }

    it "ingests the MODS file and TIFFs with metadata overrides" do
      output = service.ingest
      expect(output).to be_kind_of EphemeraFolder
      expect(output.member_ids.length).to eq 3
      expect(output.decorate.genre).to eq "ephemera"
      expect(output.decorate.members.map(&:title).flatten).to eq ["00223.tif", "00224.tif", "00223.mods"]
      expect(output.decorate.subject).to include "Free trade"
    end
  end
end
