# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::ScannedMapType do
  describe "fields" do
    it "has startPage" do
      expect(described_class).to have_field(:startPage)
    end
  end

  subject(:type) { described_class.new(scanned_map, ability: ability) }
  let(:bibid) { "5144620" }
  let(:scanned_map) do
    FactoryBot.create_for_repository(
      :scanned_map,
      viewing_hint: "individuals",
      title: ["I'm a map", "of null island"],
      viewing_direction: "left-to-right",
      portion_note: "page 1",
      source_metadata_identifier: [bibid]
    )
  end
  let(:ability) { instance_double(Ability, can?: true) }

  before do
    stub_bibdata(bib_id: bibid)
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:viewingDirection).of_type(Types::ViewingDirectionEnum) }
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:manifestUrl).of_type(String) }
    it { is_expected.to have_field(:sourceMetadataIdentifier).of_type(String) }
  end

  describe "#viewing_hint" do
    it "returns a singular value" do
      expect(type.viewing_hint).to eq "individuals"
    end
  end

  describe "#viewing_direction" do
    it "returns a singular value" do
      expect(type.viewing_direction).to eq "left-to-right"
    end
  end

  describe "#manifest_url" do
    it "links to the manifest URL" do
      expect(type.manifest_url).to eq "http://www.example.com/concern/scanned_maps/#{scanned_map.id}/manifest"
    end
  end

  describe "#thumbnail" do
    context "when a thumbnail is not set" do
      it "returns nil" do
        expect(type.thumbnail).to eq nil
      end
    end
    context "when a thumbnail is set" do
      let(:scanned_map) do
        FactoryBot.create_for_repository(
          :scanned_map,
          viewing_hint: "individuals",
          title: ["I'm a map", "of null island"],
          viewing_direction: "left-to-right",
          member_ids: file_set.id,
          thumbnail_id: file_set.id
        )
      end
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      it "returns a thumbnail service url, image, and ID for the file set" do
        expect(type.thumbnail).to eq(
          iiif_service_url: "http://www.example.com/image-service/#{file_set.id}",
          thumbnail_url: "http://www.example.com/image-service/#{file_set.id}/full/!200,150/0/default.jpg",
          id: file_set.id.to_s
        )
      end
    end
    context "when a bad thumbnail is set" do
      let(:scanned_map) do
        FactoryBot.create_for_repository(
          :scanned_map,
          viewing_hint: "individuals",
          title: ["I'm a map", "of null island"],
          viewing_direction: "left-to-right",
          thumbnail_id: "bla"
        )
      end
      it "returns nil" do
        expect(type.thumbnail).to be_nil
      end
    end
    context "when it's a MVW" do
      let(:scanned_map) do
        FactoryBot.create_for_repository(:scanned_map, thumbnail_id: volume.id)
      end
      let(:volume) do
        FactoryBot.create_for_repository(:scanned_map, thumbnail_id: file_set.id)
      end
      let(:file_set) do
        FactoryBot.create_for_repository(:file_set)
      end
      it "returns a thumbnail service url/image for the file set, but ID of the volume" do
        expect(type.thumbnail).to eq(
          iiif_service_url: "http://www.example.com/image-service/#{file_set.id}",
          thumbnail_url: "http://www.example.com/image-service/#{file_set.id}/full/!200,150/0/default.jpg",
          id: volume.id.to_s
        )
      end
    end
  end

  describe "#start_page" do
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map, start_canvas: file_set_id)
    end
    let(:file_set_id) { "i_am_a_file_set" }
    it "returns a resource's first start_canvas" do
      expect(type.start_page).to eq file_set_id.to_s
    end
  end

  describe "#label" do
    it "maps to a resource's first title with portion note" do
      expect(type.label).to eq "I'm a map (page 1)"
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{scanned_map.id}"
    end
  end

  describe "#source_metadata_identifier" do
    it "returns the bib. ID" do
      expect(type.source_metadata_identifier).to eq bibid
    end
  end

  describe "#members" do
    it "returns all members" do
      child_resource = FactoryBot.create_for_repository(:scanned_map)
      metadata_file_set = FactoryBot.create_for_repository(:geo_metadata_file_set)
      image_file_set = FactoryBot.create_for_repository(:geo_image_file_set)
      scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [metadata_file_set.id, image_file_set.id, child_resource.id])

      type = described_class.new(scanned_map, {})

      expect(type.members.map(&:id)).to eq [metadata_file_set.id, image_file_set.id, child_resource.id]
    end
  end
end
