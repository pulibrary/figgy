# frozen_string_literal: true
require "rails_helper"

RSpec.describe CoinChangeSet do
  subject(:change_set) { described_class.new(coin) }
  let(:coin) { FactoryBot.build(:coin) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:department, :die_axis, :size, :weight)
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

    it "pre-populates" do
      change_set.prepopulate!
      expect(change_set.visibility).to eq "open"
    end
  end

  describe "validations" do
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.prepopulate!
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.prepopulate!
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end
    context "when not given a coin number" do
      it "is gives it a coin number" do
        change_set.prepopulate!
        change_set.validate(coin_number: nil)
        expect(change_set).to be_valid
        expect(change_set.coin_number).to be_positive
      end
    end
    context "when given a coin number" do
      it "is uses the given coin number" do
        change_set.prepopulate!
        change_set.validate(coin_number: 5)
        expect(change_set).to be_valid
        expect(change_set.coin_number).to eq(5)
      end
    end
  end
end
