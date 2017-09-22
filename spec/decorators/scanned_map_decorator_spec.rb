# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedMapDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) do
    FactoryGirl.build(:scanned_map,
                      title: "test title",
                      author: "test author",
                      creator: "test creator",
                      subject: "test subject")
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
  context "with file sets" do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryGirl.create_for_repository(:scanned_map, member_ids: [file_set.id]) }
    it "retrieves members" do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end
end
