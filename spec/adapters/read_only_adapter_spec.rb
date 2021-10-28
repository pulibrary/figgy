# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReadOnlyAdapter do
  let(:solr_adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  it "allows resource_factory to be accessed" do
    adapter = described_class.new(solr_adapter)

    expect(adapter.resource_factory.class).to eq solr_adapter.resource_factory.class
  end

  it "allows query_service to be accessed" do
    adapter = described_class.new(solr_adapter)

    expect(adapter.query_service).to eq solr_adapter.query_service
  end

  it "errors on save" do
    resource = FactoryBot.build(:scanned_resource)
    adapter = described_class.new(solr_adapter)

    expect { adapter.persister.save(resource: resource) }.to raise_error ReadOnlyError
    expect(solr_adapter.query_service.find_all.to_a.size).to eq 0
  end

  it "errors on save_all" do
    resource = FactoryBot.build(:scanned_resource)
    resource2 = FactoryBot.build(:scanned_resource)
    adapter = described_class.new(solr_adapter)

    expect { adapter.persister.save_all(resources: [resource, resource2]) }.to raise_error ReadOnlyError
    expect(solr_adapter.query_service.find_all.to_a.size).to eq 0
  end

  it "errors on delete" do
    resource = FactoryBot.build(:scanned_resource)
    solr_adapter.persister.save(resource: resource)
    adapter = described_class.new(solr_adapter)

    expect { adapter.persister.delete(resource: resource) }.to raise_error ReadOnlyError
    expect(solr_adapter.query_service.find_all.to_a.size).to eq 1
  end
end
