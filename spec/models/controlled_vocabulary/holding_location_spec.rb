# frozen_string_literal: true
require "rails_helper"

RSpec.describe ControlledVocabulary::HoldingLocation do
  subject(:service) { described_class.new }
  describe "#all" do
    it "gets all the resources from catalog" do
      expect(service.all.map(&:label)).not_to be_blank
    end
  end
end
