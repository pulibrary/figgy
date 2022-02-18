# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserUtils do
  describe ".promote_user_to_admin" do
    let(:user) { FactoryBot.create(:user) }

    # stub out the log messages
    let(:logger) { double }
    before { allow(logger).to receive(:info) }

    it "makes the user an admin" do
      described_class.promote_user_to_admin(user: user, logger: logger)
      expect(user.admin?).to be true
    end
  end
end
