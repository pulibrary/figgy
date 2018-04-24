# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraBoxChangeSet do
  subject(:change_set) { described_class.new(FactoryBot.build(:ephemera_box)) }
  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "drive_barcode" do
    it "is invalid if the drive barcode is invalid" do
      expect(change_set).to be_valid

      change_set.drive_barcode = ["11111111111111"]
      expect(change_set).not_to be_valid
    end

    it "is valid if the drive barcode is valid" do
      expect(change_set).to be_valid
      change_set.drive_barcode = ["11111111111110"]
      expect(change_set).to be_valid
    end
  end

  describe "#state" do
    it "pre-populates" do
      change_set.prepopulate!
      expect(change_set.state).to eq "new"
    end
  end

  describe "validations" do
    context "when given a non-UUID for a collection" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ['not-valid'])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a collection which does not exist" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ['b8823acb-d42b-4e62-a5c9-de5f94cbd3f6'])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ['not-valid'])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ['55a14e79-710d-42c1-86aa-3d8cdaa62930'])
        expect(change_set).not_to be_valid
      end
    end
  end
end
