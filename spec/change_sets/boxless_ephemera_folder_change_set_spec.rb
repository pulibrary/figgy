# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BoxlessEphemeraFolderChangeSet do
  subject(:change_set) { described_class.new(FactoryGirl.build(:ephemera_folder)) }

  it_behaves_like "an ephemera folder change set", described_class

  describe "#barcode" do
    it "is not required" do
      expect(change_set.required?(:barcode)).to eq false
    end
  end

  describe "#folder_number" do
    it "is not required" do
      expect(change_set.required?(:folder_number)).to eq false
    end
  end
end
