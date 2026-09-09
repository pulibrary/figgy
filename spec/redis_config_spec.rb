require "rails_helper"

RSpec.describe RedisConfig do
  describe ".config" do
    context "when in staging" do
      before do
        allow(Rails).to receive(:env).and_return("staging")
        RedisConfig.reset!
      end
      after do
        RedisConfig.reset!
      end
      it "returns a config with sentinels" do
        expect(described_class.config[:sentinels]).not_to be_blank
        expect(described_class.config[:sentinels][0][:host]).not_to be_blank
        binding.pry
      end
    end
  end
end
