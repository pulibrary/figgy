# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticArtistDecorator do
  subject(:decorator) { described_class.new(artist) }
  let(:artist) { NumismaticArtist.new(person: "artist person", role: "artist role") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "renders the artist title" do
      expect(decorator.title).to eq("artist person, artist role")
    end
  end
end
