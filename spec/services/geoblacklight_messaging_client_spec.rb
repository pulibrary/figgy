# frozen_string_literal: true

require "rails_helper"

RSpec.describe GeoblacklightMessagingClient do
  subject(:client) { described_class.new(url) }
  let(:url) { "amqp://test.x.z.s:4000" }
  before do
    allow_any_instance_of(Logger).to receive(:warn)
  end
  describe "#publish" do
    context "when the URL is bad" do
      it "doesn't error" do
        expect { client.publish("testing") }.not_to raise_error
      end
    end
  end
end
