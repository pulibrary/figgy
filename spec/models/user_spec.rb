# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryGirl.create(:user) }
  describe "#to_s" do
    it "returns the user's NetID" do
      expect(user.to_s).to eq user.uid
    end
  end
  describe "#admin?" do
    subject(:user) { FactoryGirl.create(:admin) }
    it "returns true" do
      expect(user).to be_admin
    end
  end

  describe ".from_omniauth" do
    it "creates a user" do
      token = double("token", provider: "cas", uid: "test")
      user = described_class.from_omniauth(token)
      expect(user).to be_persisted
      expect(user.provider).to eq "cas"
      expect(user.uid).to eq "test"
    end
  end
end
