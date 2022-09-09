# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindIdsWithPropertyNotEmpty do
  it "returns all resource ids where the given property has a value" do
    stub_catalog(bib_id: "123456")
    resource1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")
    FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: nil)
    resource3 = FactoryBot.create_for_repository(:scanned_map, source_metadata_identifier: "123456")
    FactoryBot.create_for_repository(:file_set)

    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service

    expect(query_service.custom_queries.find_ids_with_property_not_empty(property: :source_metadata_identifier).to_a).to contain_exactly resource1.id, resource3.id
  end
end
