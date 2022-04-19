# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::ScannedResourceType do
  subject(:type) { described_class.new(scanned_resource, ability: ability) }
  let(:bibid) { "123456" }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      viewing_hint: "individuals",
      title: ["I'm a little teapot", "short and stout"],
      viewing_direction: "left-to-right",
      source_metadata_identifier: [bibid]
    )
  end
  let(:ability) { instance_double(Ability) }

  before do
    allow(ability).to receive(:can?).and_return(true)
    stub_bibdata(bib_id: bibid)
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:manifestUrl).of_type(String) }
    it { is_expected.to have_field(:viewingDirection).of_type(Types::ViewingDirectionEnum) }
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:ocrContent) }
    it { is_expected.to have_field(:sourceMetadataIdentifier).of_type(String) }
    it { is_expected.to have_field(:startPage).of_type(String) }
    it { is_expected.to have_field(:embed).of_type(Types::EmbedType) }
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

  describe "#thumbnail" do
    context "when a thumbnail is not set" do
      it "returns nil" do
        expect(type.thumbnail).to eq nil
      end
    end
    context "when a thumbnail is set" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          viewing_hint: "individuals",
          title: ["I'm a little teapot", "short and stout"],
          viewing_direction: "left-to-right",
          member_ids: file_set.id,
          thumbnail_id: file_set.id
        )
      end
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      it "returns nil if there's no manifest permissions" do
        allow(ability).to receive(:can?).with(:manifest, anything).and_return(false)
        expect(type.thumbnail).to eq nil
      end
      it "returns a thumbnail service url, image, and ID for the file set" do
        expect(type.thumbnail).to eq(
          iiif_service_url: "http://www.example.com/image-service/#{file_set.id}",
          thumbnail_url: "http://www.example.com/image-service/#{file_set.id}/full/!200,150/0/default.jpg",
          id: file_set.id.to_s
        )
      end
      it "returns nil if the helper fails to return a thumbnail path" do
        allow(type.helper).to receive(:figgy_thumbnail_path).and_return(nil)
        expect(type.thumbnail).to be_nil
      end
      it "returns nil for the iiif_service_url if the URL cannot be parsed" do
        allow(type.helper).to receive(:figgy_thumbnail_path).and_return("https://images.institution.edu/invalid")
        expect(type.thumbnail).to eq(
          iiif_service_url: nil,
          thumbnail_url: "https://images.institution.edu/invalid",
          id: file_set.id.to_s
        )
      end
    end
    context "when a bad thumbnail is set" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          viewing_hint: "individuals",
          title: ["I'm a little teapot", "short and stout"],
          viewing_direction: "left-to-right",
          thumbnail_id: "bla"
        )
      end
      it "returns nil" do
        expect(type.thumbnail).to be_nil
      end
    end
    context "when it's a MVW" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: volume.id)
      end
      let(:volume) do
        FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: file_set.id)
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
    let(:scanned_resource) do
      FactoryBot.create_for_repository(:scanned_resource, start_canvas: file_set_id)
    end
    let(:file_set_id) { "i_am_a_file_set" }
    it "returns a resource's first start_canvas" do
      expect(type.start_page).to eq file_set_id.to_s
    end
  end

  describe "#label" do
    it "maps to a resource's first title" do
      expect(type.label).to eq "I'm a little teapot"
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{scanned_resource.id}"
    end
  end

  describe "#manifest_url" do
    it "links to the manifest URL" do
      expect(type.manifest_url).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest"
    end
  end

  describe "#orangelight_id" do
    it "returns the bib. ID" do
      expect(type.orangelight_id).to eq bibid
    end
  end

  describe "#source_metadata_identifier" do
    it "returns the bib. ID" do
      expect(type.source_metadata_identifier).to eq bibid
    end
  end

  describe "#members" do
    it "returns all members" do
      child_resource = FactoryBot.create_for_repository(:scanned_resource)
      metadata_file_set = FactoryBot.create_for_repository(:geo_metadata_file_set)
      image_file_set = FactoryBot.create_for_repository(:geo_image_file_set)
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [metadata_file_set.id, image_file_set.id, child_resource.id])

      type = described_class.new(scanned_resource, {})

      expect(type.members.map(&:id)).to eq [metadata_file_set.id, image_file_set.id, child_resource.id]
    end
  end

  describe "#ocr_content" do
    it "returns all FileSet ocr_content" do
      child_resource = FactoryBot.create_for_repository(:file_set, ocr_content: "test")
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: child_resource.id)

      type = described_class.new(scanned_resource, {})

      expect(type.ocr_content).to eq ["test"]
    end
  end

  describe "#embed" do
    context "when resource is public" do
      let(:scanned_resource) do
        FactoryBot.create_for_repository(
          :complete_open_scanned_resource
        )
      end
      it "sets the right embed" do
        expect(type.embed).to eq(
          {
            html: "<iframe>",
            status: "authorized"
          }
        )
      end
    end

    # download permission
    context "when resource is a reading room zip file" do
      context "when user is not logged in" do
        it "returns unauthenticated" do
          {
            embed: {
              html: nil,
              status: "unauthenticated"
            }
          }
        end
      end

      context "when OARSC-permitted user is logged in" do
        it "returns a download link and authorized" do
          {
            embed: {
              html: "<a href='yadayada'></a>",
              status: "authorized"
            }
          }
        end
      end

      context "when nonpermitted user is logged in" do
        it "returns unauthorized" do
          {
            embed: {
              html: nil,
              status: "unauthorized"
            }
          }
        end
      end
    end

    # read permission
    context "when resource is a reading room viewer-viewable resource" do
      context "when OARSC-permitted user is logged in" do
        it "returns an iframe and authorized" do
          {
            embed: {
              html: "<iframe>",
              status: "authorized"
            }
          }
        end
      end
    end

    context "when resource is private" do
      context "and a permitted user is logged in" do
        it "returns an iframe and authorized" do
          {
            embed: {
              html: "<iframe>",
              status: "authorized"
            }
          }
        end
      end
    end
  end
end
