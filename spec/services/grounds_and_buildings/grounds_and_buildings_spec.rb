# frozen_string_literal: true
require "rails_helper"
require "csv"
include ActiveJob::TestHelper

RSpec.describe GroundsAndBuildingsService do
  with_queue_adapter :inline
  let(:service) { described_class.new(collection, table, csp) }
  let(:table) { CSV.parse(File.read(filepath), headers: true) }
  let(:filepath) { Rails.root.join("spec", "fixtures", "grounds_and_buildings", "brief.csv") }
  let(:componentID) {"AC111_c0161" }
  let(:collection) {"AC111"}
  let(:csp) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: disk) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:disk) { Valkyrie::StorageAdapter.find(:disk) }
  let(:query_service) { adapter.query_service }
  let(:change_set_class) { ScannedResourceChangeSet }

  it "has items" do
    expect(service.items.count).to eq(9)
  end

  it "has components" do
    expect(service.components).to include('AC111_c0143')
  end

  it "finds mvw groups" do
    expect(service.children('AC111_c0161')).to include("a6fb5c97-4b1f-41b3-b6d7-d7a8603e9bed")
  end

  context "when there is an existing component resource" do
    it "adds the associated resources to member_ids" do
       stub_request(:get, "https://findingaids.princeton.edu/collections/AC111/c0161.xml?scope=record").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'User-Agent'=>'Faraday v0.12.2'
           }).
         to_return(status: 200, body: "", headers: {})

       stub_request(:get, "https://findingaids.princeton.edu/collections/AC111/c0161.xml").
         with(
           headers: {
       	  'Accept'=>'*/*',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'User-Agent'=>'Faraday v0.12.2'
           }).
         to_return(status: 200, body: "", headers: {})

      component_resource = FactoryBot.create_for_repository(
        :scanned_resource,
        source_metadata_identifier: componentID,
        import_metadata: false)
      
      change_set = change_set_class.new(component_resource, characterize: false)
      output = service.add_members_to_mvw(component_resource)
      expect(output.member_ids).not_to be_empty
    end
  end
end
