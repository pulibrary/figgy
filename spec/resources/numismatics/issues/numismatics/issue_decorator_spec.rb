# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::IssueDecorator do
  subject(:decorator) { described_class.new(issue) }
  let(:issue) do
    FactoryBot.create_for_repository(:numismatic_issue,
                                     member_ids: [coin.id],
                                     state: "complete",
                                     numismatic_citation: numismatic_citation,
                                     numismatic_artist: numismatic_artist,
                                     numismatic_note: numismatic_note,
                                     numismatic_subject: numismatic_subject,
                                     obverse_attribute: numismatic_attribute,
                                     reverse_attribute: numismatic_attribute,
                                     earliest_date: "-91",
                                     latest_date: "-41")
  end
  let(:coin) { FactoryBot.create_for_repository(:coin) }
  let(:numismatic_citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:numismatic_artist) { Numismatics::Artist.new(person_id: person.id, signature: "artist signature") }
  let(:numismatic_attribute) { Numismatics::Attribute.new(description: "attribute description", name: "attribute name") }
  let(:numismatic_note) { Numismatics::Note.new(note: "note", type: "note type") }
  let(:numismatic_subject) { Numismatics::Subject.new(type: "Animal", subject: "unicorn") }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "#decorated_coins" do
    it "returns decorated member coins" do
      expect(decorator.decorated_coins.map(&:id)).to eq [coin.id]
    end
    it "provides a coin count" do
      expect(decorator.coin_count).to eq 1
    end
  end

  describe "#attachable_objects" do
    it "allows attaching coins" do
      expect(decorator.attachable_objects).to eq([Numismatics::Coin])
    end
  end

  describe "#citations" do
    it "renders the nested citations" do
      expect(decorator.citations).to eq(["short-title citation part citation number"])
    end
  end

  describe "#artists" do
    it "renders the nested artists" do
      expect(decorator.artists).to eq(["name1 name2, artist signature"])
    end
  end

  describe "#subjects" do
    it "renders the nested subjects" do
      expect(decorator.subjects).to eq(["Animal, unicorn"])
    end
  end

  describe "#notes" do
    it "renders the nested notes" do
      expect(decorator.notes).to eq(["note"])
    end
  end

  describe "#obverse_attributes" do
    it "renders the nested notes" do
      expect(decorator.obverse_attributes).to eq(["attribute name, attribute description"])
    end
  end

  describe "#reverse_attributes" do
    it "renders the nested notes" do
      expect(decorator.reverse_attributes).to eq(["attribute name, attribute description"])
    end
  end

  describe "state" do
    it "allows access to complete items" do
      expect(decorator.state).to eq("complete")
      expect(decorator.grant_access_state?).to be true
    end
  end

  describe "#manageable_structure" do
    it "does not manage structure" do
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#manageable_files" do
    it "does not manage files" do
      expect(decorator.manageable_files?).to be false
    end
  end

  describe "#manageable_order" do
    it "manages order" do
      expect(decorator.manageable_order?).to be true
    end
  end

  describe "#date_range" do
    it "concatenates earliest and latest dates" do
      expect(decorator.date_range).to eq("-91 to -41")
    end

    context "when both earliest and latest dates are nil" do
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }

      it "returns a nil value" do
        expect(decorator.date_range).to be_nil
      end
    end

    context "when just one date is nil" do
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, earliest_date: "-91") }
      it "returns that date value" do
        expect(decorator.date_range).to eq "-91"
      end
    end
  end
end
