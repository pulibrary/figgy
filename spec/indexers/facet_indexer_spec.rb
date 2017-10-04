# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FacetIndexer do
  describe ".to_solr" do
    it "indexes relevant facets" do
      stub_bibdata(bib_id: "123456")
      scanned_resource = FactoryGirl.create(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
      output = described_class.new(resource: scanned_resource).to_solr

      expect(output[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
      expect(output[:display_language_ssim]).to eq ["English"]
    end
  end
end
