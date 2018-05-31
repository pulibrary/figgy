# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

describe ManifestBuilder::ThumbnailBuilder do
  with_queue_adapter :inline
  subject(:output) { builder.apply(manifest) }
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file]) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  let(:manifest) { ManifestBuilder::ManifestServiceLocator.iiif_manifest_factory.new }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource)
  end
  let(:root_node) { ManifestBuilder::RootNode.new(scanned_resource) }
  let(:builder) { described_class.new(root_node) }

  describe "#apply" do
    context "when viewing a Scanned Resource" do
      let(:persisted) do
        change_set_persister.save(change_set: change_set)
      end

      before do
        persisted
      end

      it "appends the transformed metadata to the Manifest" do
        expect(output["thumbnail"]).not_to be_blank
        expect(output["thumbnail"]).to include "@id"
        expect(output["thumbnail"]["@id"]).to eq "http://www.example.com/image-service/#{persisted.member_ids.first}/full/!200,150/0/default.jpg"

        expect(output["thumbnail"]).to include "service"
        expect(output["thumbnail"]["service"]).to include "@id"
        expect(output["thumbnail"]["service"]["@id"]).to eq "http://www.example.com/image-service/#{persisted.member_ids.first}"
      end
    end

    context "when the FileSet cannot be loaded" do
      let(:persisted) do
        cs = ScannedResourceChangeSet.new(scanned_resource, thumbnail_id: ["invalid-id"])
        change_set_persister.save(change_set: cs)
      end

      it "logs a warning" do
        output = builder.apply(manifest)
        expect(output["thumbnail"]).to be_blank
      end
    end
  end
end
