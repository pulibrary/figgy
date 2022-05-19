# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::ExtractArchivalCollectionCode do
  let(:change_set) { ChangeSet.for(resource) }
  let(:resource) { FactoryBot.build(:scanned_resource, source_metadata_identifier: source_metadata_id) }

  context "with pulfa collection and component ids" do
    let(:source_metadata_id) { "C0652_c0377" }
    before { stub_findingaid(pulfa_id: source_metadata_id) }

    it "extracts the collection code" do
      updated = described_class.new(change_set_persister: nil, change_set: change_set).run
      expect(updated.model.archival_collection_code).to eq "C0652"
    end
  end

  context "with a pulfa collection id" do
    let(:source_metadata_id) { "C0652" }
    before { stub_findingaid(pulfa_id: source_metadata_id) }

    it "extracts the collection code" do
      updated = described_class.new(change_set_persister: nil, change_set: change_set).run
      expect(updated.model.archival_collection_code).to eq "C0652"
    end
  end

  context "with a bibdata id" do
    let(:source_metadata_id) { "4609321" }
    before { stub_bibdata(bib_id: source_metadata_id) }

    it "does nothing" do
      updated = described_class.new(change_set_persister: nil, change_set: change_set).run
      expect(updated).to be nil
    end
  end
end
