# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraProjectDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_project, top_language: [term.id]) }
  let(:term) { FactoryBot.create_for_repository(:ephemera_term) }

  describe "decoration" do
    it "decorates an EphemeraProject" do
      expect(resource.decorate).to be_a described_class
    end
  end

  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end

  it "does not manage structures" do
    expect(decorator.manageable_structure?).to be false
  end

  describe "#slug" do
    it "generates a slug" do
      expect(decorator.slug).to eq "test_project-1234"
    end
  end

  describe "#iiif_manifest_attributes" do
    it 'includes the "exhibit" property in the IIIF Manifest metadata' do
      expect(decorator.iiif_manifest_attributes).to include(exhibit: "test_project-1234")
    end
  end

  describe "#top_language" do
    it "returns an array of terms" do
      expect(decorator.top_language.size).to eq 1
      expect(decorator.top_language.first.id).to eq term.id
    end
  end

  context "when there are folders and boxes attached" do
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, folder.id]) }

    it "provides access to folders" do
      expect(decorator.folders.map(&:id)).to eq([folder.id])
    end

    it "provides access to boxes" do
      expect(decorator.boxes.map(&:id)).to eq([box.id])
    end
  end
end
