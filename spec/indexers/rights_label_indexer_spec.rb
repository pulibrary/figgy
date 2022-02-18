# frozen_string_literal: true

require "rails_helper"

RSpec.describe RightsLabelIndexer do
  describe ".to_solr" do
    it "indexes the rights statement label" do
      book = FactoryBot.create_for_repository(:scanned_resource)
      output = described_class.new(resource: book).to_solr
      expect(output[:rights_ssim]).to eq "No Known Copyright"
    end
  end
end
