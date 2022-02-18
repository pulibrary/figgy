# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe InstrumentedStorageAdapter do
  it_behaves_like "a Valkyrie::StorageAdapter"
  let(:storage_adapter) { described_class.new(storage_adapter: Valkyrie::StorageAdapter.find(:disk), tracer: tracer) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:tracer) { Datadog.tracer }

  context "when used" do
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
    it "instruments times to datadog" do
      uploaded_file = storage_adapter.upload(file: file, original_filename: "example.tif", resource: ScannedResource.new)
      storage_adapter.handles?(id: uploaded_file.id)
      reloaded = storage_adapter.find_by(id: uploaded_file.id)
      storage_adapter.delete(id: reloaded.id)

      expect(tracer).to have_received(:trace).with("valkyrie.storage").exactly(4).times
      expect(span).to have_received(:resource=).with("valkyrie.storage.upload")
      expect(span).to have_received(:resource=).with("valkyrie.storage.handles?")
      expect(span).to have_received(:resource=).with("valkyrie.storage.delete")
      expect(span).to have_received(:resource=).with("valkyrie.storage.find_by")
    end
  end
end
