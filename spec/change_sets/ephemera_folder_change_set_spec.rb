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

  context "within a box" do
    let(:change_set) { described_class.new(resource) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }

    describe "required fields" do
      it "are required" do
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id)
        expect(change_set.required?(:barcode)).to eq true
        expect(change_set.required?(:folder_number)).to eq true
        expect(change_set.required?(:height)).to eq true
        expect(change_set.required?(:width)).to eq true
      end
    end
  end

  context "within a project" do
    let(:change_set) { described_class.new(resource) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }

    describe "required field overrides" do
      it "are not required" do
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: resource.id)
        expect(change_set.required?(:barcode)).to eq false
        expect(change_set.required?(:folder_number)).to eq false
        expect(change_set.required?(:height)).to eq false
        expect(change_set.required?(:width)).to eq false
      end
    end
  end
end
