# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderChangeSet do
  let(:change_set) { described_class.new(FactoryBot.build(:ephemera_folder)) }

  it_behaves_like "an ephemera folder change set", described_class

  describe "#barcode" do
    it "is required" do
      expect(change_set.required?(:barcode)).to eq true
    end
  end

  describe "#folder_number" do
    it "is required" do
      expect(change_set.required?(:folder_number)).to eq true
    end
  end

  describe "#member_ids" do
    it "is not required" do
      expect(change_set.required?(:member_ids)).to eq false
    end
  end

  describe "#subject" do
    let(:change_set) { described_class.new(FactoryBot.build(:ephemera_folder, subject: nil)) }
    it "is required" do
      expect(change_set.required?(:subject)).to eq true
      expect(change_set).not_to be_valid
      expect(described_class.new(FactoryBot.build(:ephemera_folder, subject: "test"))).to be_valid
    end
  end

  describe "#visibility" do
    let(:change_set) { described_class.new(FactoryBot.build(:ephemera_folder, visibility: nil)) }
    it "has a default of open" do
      change_set.prepopulate!
      expect(change_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  describe "#series" do
    it "is multi-valued" do
      expect(change_set.multiple?(:series)).to be true
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
