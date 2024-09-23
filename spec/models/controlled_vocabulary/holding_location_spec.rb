# frozen_string_literal: true
require "rails_helper"

RSpec.describe ControlledVocabulary::HoldingLocation do
  subject(:service) { described_class.new }
  describe "#all" do
    it "gets all the resources from catalog" do
      expect(service.all.map(&:label)).not_to be_blank
      expect(service.find("http://bibdata.princeton.edu/locations/delivery_locations/1")).not_to be_nil
      expect(service.find("https://bibdata.princeton.edu/locations/delivery_locations/1")).not_to be_nil
    end
    it "is protocol agnostic" do
      stub_request(:get, "https://bibdata.princeton.edu/locations/digital_locations.json")
        .to_return(
          status: 200,
          body: File.read(Rails.root.join("spec", "fixtures", "files", "holding_locations_http.json")),
          headers: { "Content-Type" => "application/json" }
        )
      expect(service.all.first.value).to eq "https://bibdata.princeton.edu/locations/delivery_locations/1"
    end
  end
end
