# frozen_string_literal: true
require "rails_helper"

RSpec.describe PlaylistDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:playlist) }
  describe "decoration" do
    it "decorates a Playlist" do
      expect(resource.decorate).to be_a described_class
    end
  end

  describe "#displayed_attributes" do
    it "renders only the title, visibility, and authorized link" do
      expect(resource.decorate.displayed_attributes).to eq([:internal_resource, :created_at, :updated_at, :title, :visibility, :authorized_link])
    end
  end
end
