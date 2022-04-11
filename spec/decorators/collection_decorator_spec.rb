# frozen_string_literal: true
require "rails_helper"

RSpec.describe CollectionDecorator do
  subject(:decorator) { described_class.new(collection) }
  let(:collection) { FactoryBot.build(:collection, id: "1234") }

  it_behaves_like "a CollectionDecorator"

  describe "#title" do
    it "exposes the title" do
      expect(decorator.title).to eq "Title"
    end
  end

  describe "#owners" do
    let(:collection) do
      FactoryBot.build(:collection,
                       owners: ["owner"], description: ["test description"])
    end
    it "displays the owners" do
      expect(decorator.display_attributes[:owners]).to eq ["owner"]
    end
    it "displays the description" do
      expect(decorator.display_attributes[:description]).to eq ["test description"]
    end
    it "displays the DPUL url" do
      expect(decorator.display_attributes[:rendered_dpul_url]).to eq ["<a href=\"https://dpul.princeton.edu/test\">https://dpul.princeton.edu/test</a>"]
    end
  end

  describe "#members_count" do
    it "returns the number of members it has" do
      collection = FactoryBot.create_for_repository(:collection)
      2.times do
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
      end

      decorator = described_class.new(collection)

      expect(decorator.members_count).to eq 2
    end
  end

  describe "#human_readable_type" do
    context "with a Archival Media Collection" do
      let(:collection) { FactoryBot.build(:collection, change_set: "archival_media_collection") }

      it "returns Archival Media Collection" do
        expect(decorator.human_readable_type).to eq "Archival Media Collection"
      end
    end
  end
end
