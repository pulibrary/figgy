# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedMapDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) do
    FactoryBot.build(:scanned_map,
                     title: "test title",
                     author: "test author",
                     creator: "test creator",
                     references: links.to_json,
                     subject: "test subject")
  end
  let(:links) do
    {
      "http://www.jstor.org/stable/1797655": ["www.jstor.org"],
      "iiif_manifest_paths": "https://plum.princeton.edu/concern/image_works/pb8518582r/manifest"
    }
  end
  describe "#iiif_manifest_attributes" do
    it "returns attributes" do
      expect(decorator.iiif_manifest_attributes).to include title: ['test title']
      expect(decorator.iiif_manifest_attributes).to include author: ['test author']
      expect(decorator.iiif_manifest_attributes).to include creator: ['test creator']
      expect(decorator.iiif_manifest_attributes).to include subject: ['test subject']
    end
  end
  it "exposes markup for rights statement" do
    expect(resource.decorate.rendered_rights_statement).not_to be_empty
    expect(resource.decorate.rendered_rights_statement.first).to match(/#{Regexp.escape('http://rightsstatements.org/vocab/NKC/1.0/')}/)
  end
  it "exposes markup for rendered coverage" do
    expect(resource.decorate.rendered_coverage).to match(/#{Regexp.escape('boundingBoxSelector')}/)
    expect(resource.decorate.rendered_coverage).to match(/#{Regexp.escape('Toggle Map')}/)
  end
  it "exposes markup for rendered links" do
    expect(resource.decorate.rendered_links).to include(/www.jstor.org/)
    expect(resource.decorate.rendered_links).not_to include(/manifest/)
  end
  it "can attach folders" do
    expect(resource.decorate.attachable_objects).to include ScannedMap
  end
  it "can manage structure" do
    expect(decorator.manageable_structure?).to be true
  end
  describe "#display_imported_language" do
    context "with imported metadata" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
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
        FactoryBot.build(:scanned_map,
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
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, member_ids: [file_set.id]) }
    it "retrieves members" do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end
end
