# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraBoxChangeSet do
  subject(:change_set) { described_class.new(FactoryGirl.build(:ephemera_box)) }
  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "#state" do
    it "pre-populates" do
      change_set.prepopulate!
      expect(change_set.state).to eq "new"
    end
  end
end
