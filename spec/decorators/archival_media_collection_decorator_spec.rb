# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ArchivalMediaCollectionDecorator do
  subject(:decorator) { described_class.new(collection) }
  let(:collection) { FactoryBot.build(:archival_media_collection) }

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

  context 'with imported metadata' do
    let(:collection) do
      FactoryBot.build(:archival_media_collection,
                       imported_metadata: [{
                         created: "2018-05-02T11:41:06.371-05:00",
                         language: "eng"
                       }])
    end

    describe "#imported_created" do
      it "maps date to readable string" do
        expect(decorator.imported_created).to eq ["May 2, 2018"]
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
end
