# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::EphemeraFolderType do
  subject(:type) { make_graphql_object(described_class, ephemera_folder, { ability: ability }) }
  let(:ephemera_folder) do
    FactoryBot.create_for_repository(
      :ephemera_folder,
      viewing_hint: "individuals",
      title: ["I'm a little teapot", "short and stout"],
      viewing_direction: "left-to-right"
    )
  end
  let(:ability) { instance_double(Ability, can?: true) }

  describe "fields" do
    it "has startPage" do
      expect(described_class).to have_field(:startPage)
    end
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:manifestUrl).of_type(String) }
    it { is_expected.to have_field(:viewingDirection).of_type(Types::ViewingDirectionEnum) }
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:members) }
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
      let(:ephemera_folder) do
        FactoryBot.create_for_repository(
          :ephemera_folder,
          viewing_hint: "individuals",
          title: ["I'm a little teapot", "short and stout"],
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
      let(:ephemera_folder) do
        FactoryBot.create_for_repository(
          :ephemera_folder,
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
  end

  describe "#start_page" do
    let(:ephemera_folder) do
      FactoryBot.create_for_repository(:ephemera_folder, start_canvas: file_set_id)
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
      expect(type.url).to eq "http://www.example.com/catalog/#{ephemera_folder.id}"
    end
  end

  describe "#manifest_url" do
    it "links to the manifest URL" do
      expect(type.manifest_url).to eq "http://www.example.com/concern/ephemera_folders/#{ephemera_folder.id}/manifest"
    end
  end

  describe "#members" do
    it "returns all members" do
      file_set = FactoryBot.create_for_repository(:file_set)
      ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder, member_ids: [file_set.id])
      type = make_graphql_object(described_class, ephemera_folder)
      expect(type.members.map(&:id)).to eq [file_set.id]
    end
  end
end
