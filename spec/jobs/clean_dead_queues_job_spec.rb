# frozen_string_literal: true

require "rails_helper"

RSpec.describe CleanDeadQueuesJob do
  describe ".perform" do
    let(:sidekiq_dead_set) { instance_double(Sidekiq::DeadSet) }
    before do
      allow(sidekiq_dead_set).to receive(:clear)
      stub_const("Sidekiq::DeadSet", sidekiq_dead_set)
    end
    it "clears the queue for dead jobs" do
      described_class.perform_now
      expect(sidekiq_dead_set).to have_received(:clear)
    end
  end
end
