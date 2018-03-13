# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/derivatives/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe VectorWorkDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    VectorWorkDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:vector_work) do
    change_set_persister.save(change_set: VectorWorkChangeSet.new(VectorWork.new, files: [file]))
  end
  let(:vector_work_members) { query_service.find_members(resource: vector_work) }
  let(:valid_resource) { vector_work_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }
  let(:tika_output) { tika_shapefile_output }

  describe "#valid?" do
    let(:valid_file) { derivative_service.new(valid_change_set) }

    context "when given an invalid mime_type" do
      before { allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"]) }
      it "does not validate" do
        expect(valid_file).not_to be_valid
      end
    end
  end

  it "creates a zipped display vector intermediate file and a thumbnail" do
    resource = query_service.find_by(id: valid_resource.id)
    shapefiles = resource.file_metadata.find_all { |f| f.label == ["display_vector.zip"] }
    thumbnails = resource.file_metadata.find_all { |f| f.label == ["thumbnail.png"] }
    expect(shapefiles.count).to eq 1
    expect(thumbnails.count).to eq 1
  end

  describe "#cleanup_derivatives" do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(valid_change_set).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
    end
  end
end
