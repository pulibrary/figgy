# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe InstrumentedAdapter do
  let(:adapter) do
    described_class.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), tracer: tracer)
  end
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  let(:index_solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:tracer) { Datadog.tracer }
  it_behaves_like "a Valkyrie::Persister"

  describe "saving" do
    let(:tracer) { tracer_stub }
    let(:tracer_stub) { instance_double(Datadog::Tracer) }
    let(:span) { instance_double(Datadog::Span) }
    before do
      allow(tracer).to receive(:trace).and_yield(span)
      allow(span).to receive(:service=)
      allow(span).to receive(:span_type=)
      allow(span).to receive(:resource=)
      allow(span).to receive(:set_tag)
    end

    it "instruments information to datadog" do
      resource = ScannedResource.new
      output = adapter.persister.save(resource: resource)
      adapter.persister.save_all(resources: [output])
      adapter.query_service.find_by(id: output.id)
      adapter.query_service.find_all
      adapter.query_service.find_members(resource: output)
      adapter.query_service.find_parents(resource: output)
      adapter.query_service.find_references_by(resource: output, property: :member_ids)
      adapter.query_service.find_inverse_references_by(resource: output, property: :member_ids)
      adapter.query_service.find_all_of_model(model: resource.class)
      adapter.persister.delete(resource: output)
      expect(tracer).to have_received(:trace).with("valkyrie.query").exactly(7).times
      expect(tracer).to have_received(:trace).with("valkyrie.persist").exactly(3).times
      expect(span).to have_received(:resource=).with("valkyrie.save")
      expect(span).to have_received(:resource=).with("valkyrie.save_all")
      expect(span).to have_received(:resource=).with("valkyrie.find_by_id")
      expect(span).to have_received(:resource=).with("valkyrie.delete")
      expect(span).to have_received(:resource=).with("valkyrie.find_all")
      expect(span).to have_received(:resource=).with("valkyrie.find_members")
      expect(span).to have_received(:resource=).with("valkyrie.find_parents")
      expect(span).to have_received(:resource=).with("valkyrie.find_references_by")
      expect(span).to have_received(:resource=).with("valkyrie.find_inverse_references_by")
      expect(span).to have_received(:resource=).with("valkyrie.find_all_of_model")
    end
  end

  describe "#find_by" do
    before do
      allow(Valkyrie.logger).to receive(:warn)
    end
    context "when an invalid ID has been provided" do
      let(:error) { ArgumentError.new("id must be a Valkyrie::ID") }
      before do
        adapter.query_service.find_by(id: 1_234_567)
      end
      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with(error.message)
      end
    end
    context "when an object cannot be found" do
      before do
        adapter.query_service.find_by(id: Valkyrie::ID.new("5f4235a3-53c0-42cc-9ada-564ea554264e"))
      end
      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end

  describe "#find_many_by_ids" do
    before do
      allow(Valkyrie.logger).to receive(:warn)
    end
    context "when an invalid ID has been provided" do
      let(:error) { ArgumentError.new("id must be a Valkyrie::ID") }
      before do
        adapter.query_service.find_many_by_ids(ids: [1_234_567])
      end
      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with(error.message)
      end
    end
  end

  describe "#find_inverse_references_by" do
    before do
      allow(Valkyrie.logger).to receive(:warn)
    end
    context "when a child resource has not been persisted" do
      let(:resource) { FactoryBot.build(:scanned_resource) }
      let(:error) { ArgumentError.new("resource is not saved") }
      before do
        adapter.query_service.find_inverse_references_by(resource: resource, property: :member_ids)
      end
      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with(error.message)
      end
    end
  end

  describe "#find_parents" do
    before do
      allow(Valkyrie.logger).to receive(:warn)
    end
    context "when a child resource has not been persisted" do
      let(:resource) { FactoryBot.build(:scanned_resource) }
      let(:error) { ArgumentError.new("resource is not saved") }
      before do
        adapter.query_service.find_parents(resource: resource)
      end
      it "logs a warning" do
        expect(Valkyrie.logger).to have_received(:warn).with(error.message)
      end
    end
  end
end
