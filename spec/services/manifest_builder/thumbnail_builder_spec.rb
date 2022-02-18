# frozen_string_literal: true

require "rails_helper"

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
      let(:output) { builder.apply(manifest) }

      it "does not raise an exception" do
        expect { output }.not_to raise_error
        expect(output["thumbnail"]).to be_blank
      end
    end

    context "when there are no image FileSets" do
      let(:audio_file_set) do
        FactoryBot.create_for_repository(:audio_file_set)
      end
      let(:persisted) do
        scanned_resource.member_ids = audio_file_set.id
        # Adding the audio file as the thumbnail is weird, but is what FileAppender does right now.
        scanned_resource.thumbnail_id = audio_file_set.id
        change_set_persister.persister.save(resource: scanned_resource)
      end
      let(:output) { builder.apply(manifest) }

      it "does not raise an exception" do
        persisted
        expect { output }.not_to raise_error
        expect(output["thumbnail"]).to be_blank
      end
    end

    context "when viewing a Multi-Volume Work" do
      let(:persisted_volume) do
        FactoryBot.create_for_repository(:scanned_resource, files: [file])
      end
      let(:parent_change_set) { ScannedResourceChangeSet.new(scanned_resource, member_ids: [persisted_volume.id], thumbnail_id: persisted_volume.id) }
      let(:persisted) do
        change_set_persister.save(change_set: parent_change_set)
      end

      before do
        persisted
      end

      it "appends the transformed metadata to the Manifest" do
        expect(output["thumbnail"]).not_to be_blank
        expect(output["thumbnail"]).to include "@id"
        expect(output["thumbnail"]["@id"]).to eq "http://www.example.com/image-service/#{persisted_volume.member_ids.first}/full/!200,150/0/default.jpg"

        expect(output["thumbnail"]).to include "service"
        expect(output["thumbnail"]["service"]).to include "@id"
        expect(output["thumbnail"]["service"]["@id"]).to eq "http://www.example.com/image-service/#{persisted_volume.member_ids.first}"
      end
    end
  end
end
