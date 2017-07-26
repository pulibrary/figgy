# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe IndexingAdapter do
  let(:adapter) do
    described_class.new(metadata_adapter: Valkyrie::Persistence::Memory::MetadataAdapter.new,
                        index_adapter: index_solr)
  end
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  let(:index_solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  it_behaves_like "a Valkyrie::Persister"

  it "can buffer into an index" do
    persister.buffer_into_index do |buffered_adapter|
      buffered_adapter.persister.save(resource: ScannedResource.new)
      expect(index_solr.query_service.find_all.to_a.length).to eq 0
    end
    expect(index_solr.query_service.find_all.to_a.length).to eq 1
  end

  it "can buffer deletes through index" do
    created = persister.save(resource: ScannedResource.new)
    persister.buffer_into_index do |buffered_adapter|
      another_one = persister.save(resource: ScannedResource.new)
      buffered_adapter.persister.delete(resource: created)
      buffered_adapter.persister.delete(resource: another_one)
    end
    expect(index_solr.query_service.find_all.to_a.length).to eq 0
  end
end
