# frozen_string_literal: true

require "rails_helper"

RSpec.describe ControlledVocabulary::DownloadableState do
  subject(:service) { described_class.new }
  describe "#all" do
    it "gets all the possible states for downloads" do
      expect(service.all.map(&:label).length).to eq 2
      expect(service.all.map(&:label).first).to eq "Public"
      expect(service.all.map(&:value).first).to eq "public"
      expect(service.all.map(&:label).last).to eq "None"
      expect(service.all.map(&:value).last).to eq "none"
    end
  end
end
