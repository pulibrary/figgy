# frozen_string_literal: true
require "rails_helper"

describe Preserver do
  with_queue_adapter :inline

  subject(:preserver) { described_class.new(change_set: change_set, change_set_persister: change_set_persister, storage_adapter: storage_adapter) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource,
                                     source_metadata_identifier: "123456",
                                     files: [file])
  end
  let(:unpreserved_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "123456", files: [file])
  end
  let(:preservation_objects) { Wayfinder.for(resource).preservation_objects }
  let(:preservation_object) { preservation_objects.first }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:change_set) { ScannedResourceChangeSet.new(unpreserved_resource) }
  let(:storage_adapter) { instance_double(Valkyrie::Storage::Disk) }
  let(:valkyrie_file) { FileMetadata.new(id: SecureRandom.uuid) }
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: storage_adapter
    )
  end
  let(:digest_md5) { instance_double(Digest::MD5) }
  let(:digest_md5_2) { instance_double(Digest::MD5) }

  describe "#preserve!" do
    before do
      stub_ezid(shoulder: shoulder, blade: blade)
      stub_bibdata(bib_id: "123456")
    end

    it "preserves the metadata node" do
      expect(preservation_object.metadata_node).not_to be nil
      expect(preservation_object.metadata_node).to be_a FileMetadata
      expect(preservation_object.metadata_node).to be_preserved_metadata
    end

    it "calculates the MD5 checksum" do
      allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)

      preserver.preserve!

      preserved = Wayfinder.for(unpreserved_resource).preservation_objects
      local_checksum = preserved.first.metadata_node.checksum.first.md5
      local_checksum_hex = [local_checksum].pack("H*")
      local_md5_checksum = Base64.strict_encode64(local_checksum_hex)

      expect(storage_adapter).to have_received(:upload).with(
        hash_including(md5: local_md5_checksum)
      )
    end

    it "uploads some basic metadata" do
      allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)

      preserver.preserve!

      expect(storage_adapter).to have_received(:upload).with(
        hash_including(
          metadata: hash_including(
            title: resource.title.first,
            local_identifier: resource.local_identifier.first,
            identifier: resource.identifier.first,
            source_metadata_identifier: resource.source_metadata_identifier.first
          )
        )
      )
    end

    context "when retrieving Preservation from a Scanned Resource" do
      let(:file_set) do
        resource.decorate.file_sets.first
      end
      let(:preservation_objects) do
        Wayfinder.for(file_set).preservation_objects
      end
      let(:change_set) { FileSetChangeSet.new(file_set) }

      it "preserves all binary nodes" do
        preservation_object
        expect(preservation_object.binary_nodes).not_to be_empty
        expect(preservation_object.binary_nodes.first).to be_a FileMetadata
        expect(preservation_object.binary_nodes.first).not_to eq file_set.file_metadata.first
      end

      it "calculates the MD5 checksum" do
        allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)
        allow(digest_md5_2).to receive(:base64digest).and_return("deKdu2vsqTLDbKQSHLietg==")
        allow(Digest::MD5).to receive(:file).and_return(digest_md5_2)

        preserver.preserve!

        expect(storage_adapter).to have_received(:upload).with(
          hash_including(md5: "Kij7cCKGeCssvy7ZpQQasQ==")
        )
      end
    end

    context "when retrieving Preservation from a ScannedMap" do
      let(:resource) do
        FactoryBot.create_for_repository(:complete_scanned_map,
                                         source_metadata_identifier: "123456",
                                         files: [file])
      end
      let(:file_set) do
        resource.decorate.file_sets.first
      end
      let(:preservation_objects) do
        Wayfinder.for(file_set).preservation_objects
      end
      let(:change_set) { FileSetChangeSet.new(file_set) }

      it "preserves all binary nodes" do
        preservation_object
        expect(preservation_object.binary_nodes).not_to be_empty
        expect(preservation_object.binary_nodes.first).to be_a FileMetadata
        expect(preservation_object.binary_nodes.first).not_to eq file_set.file_metadata.first
      end
    end
    context "when preserving an EphemeraProject" do
      let(:resource) do
        FactoryBot.create_for_repository(:ephemera_project,
                                         member_ids: folder.id)
      end
      let(:change_set) { ChangeSet.for(resource) }
      let(:folder) do
        FactoryBot.create_for_repository(:complete_ephemera_folder)
      end
      let(:preservation_objects) do
        Wayfinder.for(folder).preservation_objects
      end
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }
      it "does not preserve its children" do
        preserver.preserve!
        expect(preservation_objects).to be_blank
      end
      it "does preserve itself" do
        preserver.preserve!
        expect(Wayfinder.for(resource).preservation_object).to be_a PreservationObject
      end
    end

    context "when preserving an EphemeraBox" do
      let(:resource) do
        FactoryBot.create_for_repository(:ephemera_box,
                                         member_ids: folder.id)
      end
      let(:change_set) { ChangeSet.for(resource) }
      let(:folder) do
        FactoryBot.create_for_repository(:complete_ephemera_folder)
      end
      let(:preservation_objects) do
        Wayfinder.for(folder).preservation_objects
      end
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }
      it "does not preserve its children" do
        preserver.preserve!
        expect(preservation_objects).to be_blank
      end
      it "does preserve itself" do
        preserver.preserve!
        expect(Wayfinder.for(resource).preservation_object).to be_a PreservationObject
      end
    end
  end
end
