# frozen_string_literal: true
require "rails_helper"

RSpec.describe BrowseEverythingIngestJob do
  context "when called with a non-existent resource" do
    it "rescues and doesn't retry" do
      allow(Valkyrie.logger).to receive(:warn)

      described_class.perform_now("bla", "ScannedResourcesController", [])

      expect(Valkyrie.logger).to have_received(:warn).with("Unable to find resource with ID: bla")
    end
  end
end
