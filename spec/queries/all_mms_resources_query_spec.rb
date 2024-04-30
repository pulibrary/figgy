
# frozen_string_literal: true
require "rails_helper"

describe AllMmsResourcesQuery do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe "#all_mms_resources" do
    it "finds all resources with an mms id" do
      stub_catalog(bib_id: "9985434293506421")
      stub_findingaid(pulfa_id: "AC044_c0003")
      mms_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "9985434293506421")
      _component_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "AC044_c0003")
      expect(query.all_mms_resources.map(&:id).to_a).to eq [mms_resource.id]
    end
  end
end
