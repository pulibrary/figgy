# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::FileSetType do
  subject(:type) { make_graphql_object(described_class, resource, { ability: ability }) }
  let(:resource) { FactoryBot.create_for_repository(:file_set, viewing_hint: "individuals", title: ["I'm a label."], ocr_content: ["My Content"]) }
  let(:parent) { FactoryBot.create_for_repository(:scanned_resource, member_ids: resource.id) }
  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:label).of_type(String) }
  end
  let(:ability) { instance_double(Ability, can?: true) }

  describe "#viewing_hint" do
    it "returns a singular value" do
      expect(type.viewing_hint).to eq "individuals"
    end
  end

  describe "#ocr_content" do
    it "returns an array" do
      expect(type.ocr_content).to eq ["My Content"]
    end
  end

  describe "#label" do
    it "maps to a resource's first title" do
      expect(type.label).to eq "I'm a label."
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{resource.id}"
    end
  end

  describe "#members" do
    it "returns an empty array" do
      expect(type.members).to eq []
    end
  end

  describe "#thumbnail" do
    it "returns information for itself" do
      parent
      expect(type.thumbnail).to eq(
        iiif_service_url: "http://www.example.com/image-service/#{resource.id}",
        thumbnail_url: "http://www.example.com/image-service/#{resource.id}/full/!200,150/0/default.jpg",
        id: resource.id.to_s
      )
    end
  end
end
