# frozen_string_literal: true

# Generated with `rails generate valkyrie:model Playlist`
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Playlist do
  let(:resource_klass) { described_class }
  let(:playlist) { FactoryBot.build(:playlist) }
  it_behaves_like "a Valkyrie::Resource"

  describe ".can_have_manifests?" do
    it "can be used to generate IIIF Manifests" do
      expect(described_class.can_have_manifests?).to be true
    end
  end

  it "has a title" do
    playlist.title = ["Woodstock"]
    expect(playlist.title).to eq ["Woodstock"]
  end

  it "has visibility" do
    playlist.visibility = ["restricted"]
    expect(playlist.visibility).to eq ["restricted"]
  end

  it "has a downloadable attribute" do
    playlist.downloadable = ["public"]
    expect(playlist.downloadable).to eq ["public"]
  end
end
