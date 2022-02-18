# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { FactoryBot.create(:user) }
  describe "#to_s" do
    it "returns the user's NetID" do
      expect(user.to_s).to eq user.uid
    end
  end
  describe "#staff?" do
    subject(:user) { FactoryBot.create(:staff) }
    it "returns true" do
      expect(user).to be_staff
    end

    it "is not an admin" do
      expect(user).not_to be_admin
    end

    it "is a campus patron" do
      expect(user).to be_campus_patron
    end

    it "is not anonymous" do
      expect(user).not_to be_anonymous
    end
  end

  describe "#admin?" do
    subject(:user) { FactoryBot.create(:admin) }
    it "returns true" do
      expect(user).to be_admin
    end

    it "is a campus patron" do
      expect(user).to be_campus_patron
    end

    it "is not anonymous" do
      expect(user).not_to be_anonymous
    end
  end

  describe ".from_omniauth" do
    it "creates a user" do
      token = double("token", provider: "cas", uid: "test")
      user = described_class.from_omniauth(token)
      expect(user).to be_persisted
      expect(user.provider).to eq "cas"
      expect(user.uid).to include "test"
    end

    it "ensures that users have unique IDs" do
      token = double("token", provider: "cas", uid: "test1")
      user = described_class.from_omniauth(token)
      expect(user).to be_persisted
      expect(user.provider).to eq "cas"
      expect(user.uid).to include "test1"

      new_user = described_class.from_omniauth token
      expect(new_user).to eq user

      invalid_user = described_class.new uid: "test1"
      expect(invalid_user).not_to be_valid
      expect(invalid_user.errors).to include :uid
      expect(invalid_user.errors[:uid]).to include "has already been taken"
    end

    it "creates an email address based on netid" do
      token = double("token", provider: "cas", uid: "test")
      user = described_class.from_omniauth(token)
      expect(user.email).to eq("test@princeton.edu")
    end

    context "with an external email address as a netid" do
      it "uses the external email as-is" do
        token = double("token", provider: "cas", uid: "test@example.org")
        user = described_class.from_omniauth(token)
        expect(user.email).to eq("test@example.org")
      end
    end
  end
end
