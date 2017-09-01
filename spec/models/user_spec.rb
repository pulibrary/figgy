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

    it "is a campus patron" do
      expect(user).to be_campus_patron
    end

    it "is not anonymous" do
      expect(user).not_to be_anonymous
    end

    it "is not a completer" do
      expect(user).not_to be_completer
    end

    it "is not a curator" do
      expect(user).not_to be_curator
    end

    it "is not an editor" do
      expect(user).not_to be_editor
    end

    it "is not an ephemera editor" do
      expect(user).not_to be_ephemera_editor
    end

    it "is not a fulfiller" do
      expect(user).not_to be_fulfiller
    end

    it "is not an image editor" do
      expect(user).not_to be_image_editor
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
