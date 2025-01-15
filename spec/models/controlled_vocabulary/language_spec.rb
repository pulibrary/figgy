# frozen_string_literal: true
require "rails_helper"

RSpec.describe ControlledVocabulary::Language do
  subject(:service) { described_class.new }
  describe "#all" do
    it "gets all the possible languages" do
      expect(service.all.map(&:label).length).to eq 487
    end
  end
end
