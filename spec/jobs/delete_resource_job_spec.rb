# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeleteResourceJob do
  describe ".perform" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file], holding_location: ["https://bibdata.princeton.edu/locations/delivery_locations/1"]) }
    let(:file) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
    let(:db) { Valkyrie::MetadataAdapter.find(:postgres) }
    let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }

    it "deletes the resource from postgres and solr" do
      described_class.perform_now(resource.id.to_s)
      expect { db.query_service.find_by(id: resource.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      expect { solr.query_service.find_by(id: resource.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
