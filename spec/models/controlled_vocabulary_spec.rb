# frozen_string_literal: true
require "rails_helper"

RSpec.describe ControlledVocabulary do
  describe ".for" do
    context "when given a term that isn't registered" do
      it "returns a null vocabulary" do
        expect(described_class.for(:fake_term).all).to eq []
      end
    end
  end

  describe "ocr_language" do
    let(:vocabulary) { described_class.for(:ocr_language) }
    describe "#all" do
      it "returns all languages" do
        expect(vocabulary.all).to include ControlledVocabulary::Term.new(label: "English", value: "eng")
      end
    end
  end

  describe "notice_type" do
    let(:vocabulary) { described_class.for(:notice_type) }
    describe "#all" do
      it "returns all possible notice types that should be in the dropdown" do
        types = vocabulary.all
        expect(types.length).to eq 3
        expect(types[0].label).to eq "Harmful Content"
        expect(types[0].to_graphql[:accept_label]).to eq "View Content"
        expect(types[1].label).to eq "Explicit Content"
        expect(types[1].to_graphql[:accept_label]).to eq "View Content"
        expect(types[2].label).to eq "Senior Thesis"
        expect(types[2].to_graphql[:accept_label]).to eq "Accept"
      end
    end
  end

  describe "owners" do
    let(:vocabulary) { described_class.for(:owners) }
    describe "#all" do
      it "returns all user netids" do
        user1 = FactoryBot.create(:user, uid: "one")
        user2 = FactoryBot.create(:user, uid: "two")

        expect(vocabulary.all).to include ControlledVocabulary::Term.new(label: user1.uid, value: user1.uid)
        expect(vocabulary.all).to include ControlledVocabulary::Term.new(label: user2.uid, value: user2.uid)
      end
    end
  end
end
