# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:scanned_resource) }
  let(:resource_klass) { ScannedResource }

  it_behaves_like 'a Valkyrie::ResourceDecorator'

  describe "#imported_created" do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       title: 'test title',
                       created: '01/01/1970',
                       imported_metadata: [{
                         creator: 'test creator',
                         created: Date.parse("01/01/1970")
                       }])
    end
    it 'exposes a formatted string for the created date' do
      expect(decorator.imported_created).to eq ["January 1, 1970"]
    end
  end
  context 'with imported metadata' do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       title: 'test title',
                       author: 'test author',
                       imported_metadata: [{
                         creator: 'test creator',
                         subject: 'test subject',
                         language: 'eng'
                       }])
    end
    describe "#iiif_manifest_attributes" do
      it "returns attributes merged with the imported metadata for the IIIF Manifest" do
        expect(decorator.iiif_manifest_attributes).to include title: ['test title']
        expect(decorator.iiif_manifest_attributes).to include author: ['test author']
        expect(decorator.iiif_manifest_attributes).to include creator: ['test creator']
        expect(decorator.iiif_manifest_attributes).to include subject: ['test subject']
      end
    end
    describe "#display_imported_language" do
      it "maps keys to english strings" do
        expect(decorator.display_imported_language).to eq ["English"]
      end
    end
    describe "raw imported metadata" do
      it "is not displayed" do
        expect(decorator.display_attributes.keys).not_to include :source_metadata
      end
    end
  end

  describe '#parents' do
    let(:parent_collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [parent_collection.id]) }

    before do
      parent_collection
    end

    it 'retrieves all parent resources' do
      expect(decorator.parents.to_a).not_to be_empty
    end
  end
end
