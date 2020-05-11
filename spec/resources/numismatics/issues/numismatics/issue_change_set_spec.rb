# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::IssueChangeSet do
  subject(:change_set) { described_class.new(issue) }
  let(:issue) { FactoryBot.build(:numismatic_issue) }

  describe "capitalizing values" do
    let(:issue) do
      FactoryBot.build(
        :numismatic_issue,
        metal: "copper",
        color: "green",
        object_type: "coin",
        denomination: "grosso",
        era: "uncertain",
        obverse_figure: "bust",
        obverse_symbol: "cornucopia",
        obverse_part: "standing",
        obverse_orientation: "right",
        obverse_figure_description: "harp at left side, 5 strings.",
        obverse_figure_relationship: "jointly holding cornucopia",
        reverse_figure: "emperor and Virgin",
        reverse_symbol: "mask",
        reverse_part: "bow",
        reverse_orientation: "from above",
        reverse_figure_description: "in wreath order",
        reverse_figure_relationship: "in provocatio",
        shape: "round",

        edge: "eX regVM consVLta DeVs fortVnet VbIqVe (=1691)",
        workshop: "mint mark A",
        series: "type B",
        obverse_legend: "center: لااله الا الل",
        reverse_legend: "in exergue - JUNE 16, 1880"

        # numismatic_artist: numismatic_artist,
        # numismatic_citation: numismatic_citation,
        # numismatic_place_id: numismatic_place.id,
        # obverse_attribute: numismatic_attribute,
        # reverse_attribute: numismatic_attribute,
        # ruler_id: numismatic_person.id,
        # master_id: numismatic_person.id,
        # numismatic_monogram_ids: [numismatic_monogram1.id, numismatic_monogram2.id],
      )
    end

    it "capitalizes desired values" do
      expect(change_set.metal).to eq "Copper"
      expect(change_set.color).to eq "Green"
      expect(change_set.denomination).to eq "Grosso"
      expect(change_set.era).to eq "Uncertain"
      expect(change_set.object_type).to eq "Coin"
      expect(change_set.obverse_figure).to eq "Bust"
      expect(change_set.obverse_figure_relationship).to eq "Jointly holding cornucopia"
      expect(change_set.obverse_figure_description).to eq "Harp at left side, 5 strings."
      expect(change_set.obverse_orientation).to eq "Right"
      expect(change_set.obverse_part).to eq "Standing"
      expect(change_set.obverse_symbol).to eq "Cornucopia"
      expect(change_set.reverse_figure).to eq "Emperor and Virgin"
      expect(change_set.reverse_figure_relationship).to eq "In provocatio"
      expect(change_set.reverse_figure_description).to eq "In wreath order"
      expect(change_set.reverse_orientation).to eq "From above"
      expect(change_set.reverse_part).to eq "Bow"
      expect(change_set.reverse_symbol).to eq "Mask"
      expect(change_set.shape).to eq "Round"
    end

    it "does not capitalize fields that may have transcribed values" do
      expect(change_set.edge).to eq "eX regVM consVLta DeVs fortVnet VbIqVe (=1691)"
      expect(change_set.workshop).to eq "mint mark A"
      expect(change_set.series).to eq "type B"
      expect(change_set.obverse_legend).to eq "center: لااله الا الل"
      expect(change_set.reverse_legend).to eq "in exergue - JUNE 16, 1880"
    end

    context "when a capitalized field contains a unicode value" do
      let(:issue) do
        FactoryBot.build(
          :numismatic_issue,
          reverse_figure: "上祥云 (cloud on top)"
        )
      end
      it "respects the unicode value" do
        expect(change_set.reverse_figure).to eq "上祥云 (cloud on top)"
      end
    end
  end

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to be_a(Hash)
      expect(change_set.primary_terms.keys).to eq(["", "Obverse", "Obverse Attributes", "Reverse", "Reverse Attributes", "Artist", "Citation", "Note", "Subject", "Monograms"])
      expect(change_set.primary_terms[""]).to include(:object_type, :denomination, :metal, :workshop)
      expect(change_set.primary_terms.values.flatten).not_to include(:issue_number)
    end
  end

  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "#state" do
    it "pre-populates" do
      expect(change_set.state).to eq "complete"
    end

    context "when an issue has coin members" do
      subject(:change_set) { described_class.new(issue) }
      let(:coin) { FactoryBot.create_for_repository(:coin) }
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id], state: ["draft"]) }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

      it "does not propagate the state to member resources" do
        change_set.state = "complete"
        persisted = change_set_persister.save(change_set: change_set)
        coins = persisted.decorate.decorated_coins
        expect(coins.first.state).to eq "draft"
      end
    end
  end

  describe "validations" do
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end
    context "when earliest_date or latest_date are not dates" do
      it "is not valid" do
        change_set.validate(earliest_date: "abcd", latest_date: "1979")
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end

  describe "#prepopulate!" do
    it "builds an empty numsimatic artist" do
      change_set.prepopulate!
      expect(change_set.numismatic_artist.first).to be_a Numismatics::ArtistChangeSet
    end
  end
end
