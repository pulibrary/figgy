# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryGirl.create(:user) }
  describe "#to_s" do
    it "returns the user's email" do
      expect(user.to_s).to eq user.email
    end
  end
  describe "#admin?" do
    subject(:user) { FactoryGirl.create(:admin) }
    it "returns true" do
      expect(user).to be_admin
    end
  end
end
