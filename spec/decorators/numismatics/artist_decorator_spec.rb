# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ArtistDecorator do
  subject(:decorator) { described_class.new(artist) }
  let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:artist) { Numismatics::Artist.new(person_id: person.id, signature: "artist signature") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "renders the artist title" do
      expect(decorator.title).to eq("name1 name2, artist signature")
    end
  end
end
