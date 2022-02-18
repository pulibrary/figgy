# frozen_string_literal: true

require "rails_helper"

RSpec.describe CleanGuestUsersJob do
  describe ".perform" do
    let(:user) { instance_double(User) }
    let(:users) { [user] }
    before do
      Timecop.freeze(Time.zone.local(1990))
      allow(user).to receive(:destroy)
      allow(User).to receive(:where).and_return(users)
    end
    after { Timecop.return }
    it "queries the database for guest users and destroys them" do
      described_class.perform_now
      expect(User).to have_received(:where).with("guest = ? and updated_at < ?", true, Time.current - 7.days)
      expect(user).to have_received(:destroy)
    end
  end
end
