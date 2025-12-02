# frozen_string_literal: true
require "rails_helper"

RSpec.describe SeleneResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:scanned_resource) { ScannedResource.new(visibility: visibility) }
  let(:resource_klass) { ScannedResource }
  let(:form_resource) { scanned_resource }

  describe "persistence" do
    it "can save" do
      persisted = ChangeSetPersister.default.save(change_set: change_set)
      reloaded = ChangeSet.for(ChangeSetPersister.default.query_service.find_by(id: persisted.id))

      expect(reloaded).to be_a described_class
    end
  end

  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
  end

  describe "#meters_per_pixel" do
    it "can save a float from params" do
      change_set.validate(meters_per_pixel: "0.0025")

      expect(change_set.meters_per_pixel).to eq 0.0025
    end
  end

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(BookWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end

  describe "#change_set" do
    it "sets selene_resource by default" do
      expect(change_set.change_set).to eq "selene_resource"
    end
  end

  describe "#primary_terms" do
    it "required selene metadata" do
      expect(change_set.primary_terms).to include :ingest_path
      expect(change_set.primary_terms).to include :portion_note
      expect(change_set.primary_terms).to include :change_set
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "none"
    end
  end
end
