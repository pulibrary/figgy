# frozen_string_literal: true
require "rails_helper"

RSpec.describe CollectionDecorator do
  subject(:decorator) { described_class.new(collection) }
  let(:collection) { FactoryBot.build(:collection) }

  it_behaves_like "a CollectionDecorator"

  describe "#title" do
    it "exposes the title" do
      expect(decorator.title).to eq "Title"
    end
  end

  describe "#owners" do
    let(:collection) do
      FactoryBot.build(:collection,
                       owners: ["owner"])
    end
    it "displays the owners" do
      expect(decorator.display_attributes[:owners]).to eq ["owner"]
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
end
