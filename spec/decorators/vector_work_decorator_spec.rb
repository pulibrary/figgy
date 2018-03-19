# frozen_string_literal: true
require 'rails_helper'

RSpec.describe VectorWorkDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) do
    FactoryBot.build(:vector_work,
                     title: "test title",
                     author: "test author",
                     creator: "test creator",
                     subject: "test subject",
                     holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/14")
  end
  it "exposes markup for rights statement" do
    expect(resource.decorate.rendered_rights_statement).not_to be_empty
    expect(resource.decorate.rendered_rights_statement.first).to match(/#{Regexp.escape('http://rightsstatements.org/vocab/NKC/1.0/')}/)
  end
  it "exposes markup for rendered holding_location" do
    expect(resource.decorate.rendered_holding_location.first).to eq("Lewis Library")
  end
  it "exposes markup for rendered coverage" do
    expect(resource.decorate.rendered_coverage).to match(/#{Regexp.escape('boundingBoxSelector')}/)
    expect(resource.decorate.rendered_coverage).to match(/#{Regexp.escape('Toggle Map')}/)
  end
  it "can attach folders" do
    expect(resource.decorate.attachable_objects).to include VectorWork
  end
  it "cannot manage structure" do
    expect(decorator.manageable_structure?).to be false
  end
  describe "#display_imported_language" do
    context "with imported metadata" do
      let(:resource) do
        FactoryBot.build(:vector_work,
                         title: "test title",
                         imported_metadata: [{
                           language: "eng"
                         }])
      end

      it "maps keys to english strings" do
        expect(decorator.display_imported_language).to eq ["English"]
      end
    end
  end
  describe "#language" do
    context "with direct metadata" do
      let(:resource) do
        FactoryBot.build(:vector_work,
                         title: "test title",
                         language: ["eng"])
      end
      it "exposes the language" do
        expect(decorator.language).to eq ["English"]
      end
    end
  end
  context "with file sets" do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:vector_work, member_ids: [file_set.id]) }
    it "retrieves members" do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end
end
