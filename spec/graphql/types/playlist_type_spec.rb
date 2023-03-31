# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::PlaylistType do
  subject(:type) { make_graphql_object(described_class, playlist, {}) }
  let(:playlist) do
    FactoryBot.create_for_repository(
      :playlist,
      title: ["Playlist Title"]
    )
  end

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:manifestUrl).of_type(String) }
  end

  describe "#manifest_url" do
    it "links to the manifest URL" do
      expect(type.manifest_url).to eq "http://www.example.com/concern/playlists/#{playlist.id}/manifest"
    end
  end

  describe "#thumbnail" do
    it "always returns nil" do
      expect(type.thumbnail).to eq nil
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{playlist.id}"
    end
  end

  describe "#source_metadata_identifier" do
    it "is always nil" do
      expect(type.source_metadata_identifier).to eq nil
    end
  end

  describe "#members" do
    it "returns all proxy file set members" do
      child_resource = FactoryBot.create_for_repository(:proxy_file_set)
      resource = FactoryBot.create_for_repository(:playlist, member_ids: child_resource.id)

      type = make_graphql_object(described_class, resource, {})

      expect(type.members.map(&:id)).to eq [child_resource.id]
    end
  end

  describe "#viewing_hint" do
    it "returns nil" do
      expect(type.viewing_hint).to eq nil
    end
  end

  describe "#label" do
    it "returns the label" do
      expect(type.label).to eq "Playlist Title"
    end
  end
end
