# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe ExternalMetadataDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ExternalMetadataDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:event_generator) { instance_double(EventGenerator::GeoblacklightEventGenerator).as_null_object }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml; schema=fgdc") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:parent_resource) do
    change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, visibility: "open", files: [file]))
  end
  let(:parent_resource_members) { query_service.find_members(resource: parent_resource) }
  let(:valid_resource) { parent_resource_members.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:tika_output) { tika_xml_output }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    let(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given an invalid mime_type" do
      before { allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"]) }
      it "does not validate" do
        expect(valid_file).not_to be_valid
      end
    end

    context "when given an invalid parent resource type" do
      let(:parent_resource) do
        change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
      end

      it "does not validate" do
        expect(valid_file).not_to be_valid
      end
    end
  end

  before do
    allow(EventGenerator::GeoblacklightEventGenerator).to receive(:new).and_return(event_generator)
    allow(event_generator).to receive(:record_updated)
  end

  it "extracts metadata from the file into the parent resource and triggers an update event", rabbit_stubbed: true do
    parent = query_service.find_by(id: parent_resource.id)
    expect(parent.title).to eq ["China census data by county, 2000-2010"]
    expect(parent.visibility).to eq ["open"]
    expect(event_generator).to have_received(:record_updated).exactly(4).times
  end
end
