# frozen_string_literal: true
require 'rails_helper'

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
end
