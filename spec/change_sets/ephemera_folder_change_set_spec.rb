# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderChangeSet do
  let(:change_set) { described_class.new(FactoryGirl.build(:ephemera_folder)) }

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
end
