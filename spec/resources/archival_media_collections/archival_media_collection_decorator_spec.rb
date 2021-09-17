# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaCollectionDecorator do
  subject(:decorator) { described_class.new(collection) }
  let(:collection) { FactoryBot.build(:archival_media_collection, imported_metadata: imported_metadata) }
  let(:imported_metadata) { nil }

  it_behaves_like "a CollectionDecorator"

  describe "#identifier" do
    let(:collection) do
      FactoryBot.build(:archival_media_collection,
                       identifier: "ark:/99999/fk4")
    end
    it "displays the identifier" do
      expect(decorator.display_attributes[:identifier]).to eq ["ark:/99999/fk4"]
    end
  end

  describe "#imported_created" do
    context "with a single date" do
      let(:imported_metadata) { [{ created: "2018-05-02T11:41:06.371-05:00" }] }
      it "maps date to readable string" do
        expect(decorator.imported_created).to eq ["May 2, 2018"]
      end
    end
    context "with a date range" do
      let(:imported_metadata) { [{ created: "1941-01-01T00:00:00Z/1985-12-31T23:59:59Z" }] }
      it "maps date to readable string" do
        expect(decorator.imported_created).to eq ["1941-1985"]
      end
    end
  end

  describe "#display_imported_language" do
    let(:imported_metadata) { [{ language: "eng" }] }
    it "maps keys to english strings" do
      expect(decorator.display_imported_language).to eq ["English"]
    end
  end

  describe "raw imported metadata" do
    let(:imported_metadata) do
      [{ created: "2018-05-02T11:41:06.371-05:00",
         language: "eng" }]
    end
    it "is not displayed" do
      expect(decorator.display_attributes.keys).not_to include :source_metadata
    end
  end

  # describe "#media_resources" do
  #   let(:collection) { FactoryBot.create_for_repository(:archival_media_collection) }
  #
  #   it "returns child media resources" do
  #     FactoryBot.create_for_repository(:media_resource, member_of_collection_ids: [collection.id])
  #     FactoryBot.create_for_repository(:media_resource, member_of_collection_ids: [collection.id])
  #     FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id])
  #
  #     expect(decorator.media_resources.size).to eq 2
  #   end
  # end
end
