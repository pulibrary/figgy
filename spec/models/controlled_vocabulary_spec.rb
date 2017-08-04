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
end
