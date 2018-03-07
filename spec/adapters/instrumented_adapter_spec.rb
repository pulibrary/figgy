# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe InstrumentedAdapter do
  let(:adapter) do
    described_class.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister))
  end
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  let(:index_solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:tracer) { object_double(Datadog.tracer) }
  let(:span) { object_double(Datadog.tracer.trace("bla")) }
  it_behaves_like "a Valkyrie::Persister"

  before do
    allow(tracer).to receive(:trace).and_yield(span)
    allow(Datadog).to receive(:tracer).and_return(tracer)
    allow(span).to receive(:service=)
    allow(span).to receive(:span_type=)
    allow(span).to receive(:resource=)
  end
  describe "saving" do
    it "instruments information to datadog" do
      resource = ScannedResource.new
      output = adapter.persister.save(resource: resource)
      expect(tracer).to have_received(:trace).with("valkyrie.save")
      expect(span).to have_received(:resource=).with("ScannedResource<id: #{output.id}>")
      adapter.persister.save_all(resources: [output])
      adapter.query_service.find_by(id: output.id)
      adapter.query_service.find_all
      adapter.query_service.find_members(resource: resource)
      adapter.query_service.find_parents(resource: resource)
      adapter.query_service.find_references_by(resource: resource, property: :member_ids)
      adapter.query_service.find_inverse_references_by(resource: resource, property: :member_ids)
      adapter.query_service.find_all_of_model(model: resource.class)
      adapter.persister.delete(resource: output)
      expect(tracer).to have_received(:trace).with("valkyrie.save_all")
      expect(tracer).to have_received(:trace).with("valkyrie.find_by_id")
      expect(tracer).to have_received(:trace).with("valkyrie.delete")
      expect(tracer).to have_received(:trace).with("valkyrie.find_all")
      expect(tracer).to have_received(:trace).with("valkyrie.find_members")
      expect(tracer).to have_received(:trace).with("valkyrie.find_parents")
      expect(tracer).to have_received(:trace).with("valkyrie.find_references_by")
      expect(tracer).to have_received(:trace).with("valkyrie.find_inverse_references_by")
      expect(tracer).to have_received(:trace).with("valkyrie.find_all_of_model")
    end
  end
end
