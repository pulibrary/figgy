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
end
