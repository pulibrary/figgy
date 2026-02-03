require "rails_helper"

describe Preserver do
  include ActiveJob::TestHelper
  with_queue_adapter :inline

  subject(:preserver) { described_class.new(change_set: change_set, change_set_persister: change_set_persister, storage_adapter: storage_adapter) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource,
                                     source_metadata_identifier: "991234563506421",
                                     files: [file])
  end
  let(:unpreserved_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "991234563506421", files: [file2])
  end
  let(:preservation_objects) { Wayfinder.for(resource).preservation_objects }
  let(:preservation_object) { preservation_objects.first }
  let(:change_set) { ScannedResourceChangeSet.new(unpreserved_resource) }
  let(:storage_adapter) { instance_double(Valkyrie::Storage::Disk) }
  let(:valkyrie_file) { FileMetadata.new(id: "disk://" + Rails.root.join("tmp", "cloud_backup_test", resource.id, "#{resource.id}.json").to_s) }
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: storage_adapter
    )
  end
  let(:query_service) { change_set_persister.query_service }
  let(:digest_md5) { instance_double(Digest::MD5) }
  let(:digest_md5_2) { instance_double(Digest::MD5) }

  describe "GCS preservation settings" do
    it "is configured to have a really long timeout" do
      expect(Google::Cloud::Storage.configure.timeout).to eq 36_000
    end
  end

  describe "#preserve!" do
    before do
      stub_ezid
      stub_catalog(bib_id: "991234563506421")
    end

    context "when a race condition forces new PreservationObjects" do
      # There's a small window where two Preservers can run and both create a
      # new PreservationObject linked to the same object. This makes finding a
      # preservation object return nil to simulate that case.
      it "prevents creating the new PreservationObject by the database", db_cleaner_deletion: true do
        allow_any_instance_of(ScannedResourceWayfinder).to receive(:preservation_object).and_return(nil)
        allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)

        # This should raise an error - running Preserver again is creating a new
        # PreservationObject because it can't find one (due to our stub), and
        # there's already one from this preserving as a result of being a
        # complete object.
        expect { preserver.preserve! }.to raise_error Sequel::UniqueConstraintViolation

        preservation_objects = Wayfinder.for(unpreserved_resource).preservation_objects
        expect(preservation_objects.length).to eq 1
        # Ensure storage_adapter didn't try to upload files, otherwise two
        # preservers will fight each other for uploads.
        expect(storage_adapter).not_to have_received(:upload)
      end
    end

    it "preserves the metadata node" do
      expect(preservation_object.metadata_node).not_to be nil
      expect(preservation_object.metadata_node).to be_a FileMetadata
      expect(preservation_object.metadata_node).to be_preserved_metadata
      expect(preservation_object.metadata_version).to eq "1"
    end

    it "preserves children if asked to re-preserve and one doesn't have a PreservationObject" do
      allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)
      preservation_object
      file_set = Wayfinder.for(resource).members.first
      file_set_po = Wayfinder.for(file_set).preservation_object
      # Delete one of the member's PreservationObjects
      change_set_persister.delete(change_set: ChangeSet.for(file_set_po))

      described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister, storage_adapter: storage_adapter).preserve!
      file_set_po = Wayfinder.for(file_set).preservation_object

      expect(file_set_po).not_to be_blank
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

    context "when a resource is edited" do
      it "updates the metadata_version of the preservation object" do
        expect(preservation_object.metadata_version).to eq "1"
        updated_resource = query_service.find_by(id: resource.id)
        cs = ChangeSet.for(updated_resource)
        cs.validate(title: "new title")
        change_set_persister.save(change_set: cs)

        updated_preservation_object = query_service.find_by(id: preservation_object.id)
        expect(updated_preservation_object.metadata_version).to eq "2"
      end
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

      it "can force presevation of binary node" do
        allow(storage_adapter).to receive(:upload).and_return(valkyrie_file)
        preservation_object
        # Re-preserve with force_preservation parameter set to true
        described_class.new(change_set: change_set, change_set_persister: change_set_persister, storage_adapter: storage_adapter, force_preservation: true).preserve!

        expect(storage_adapter).to have_received(:upload).exactly(3).times
      end
    end

    context "when retrieving Preservation from a ScannedMap" do
      let(:resource) do
        FactoryBot.create_for_repository(:complete_scanned_map,
                                         source_metadata_identifier: "991234563506421",
                                         files: [file])
      end
      let(:file_set) do
        resource.decorate.decorated_file_sets.first
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

    context "when preserving a ScannedResource" do
      with_queue_adapter :inline
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }

      it "doesn't preserve if Characterization hasn't run yet, but preserves after" do
        allow(storage_adapter).to receive(:upload).and_call_original
        preserver.preserve!

        expect(storage_adapter).to have_received(:upload).with(
          hash_including(md5: "Kij7cCKGeCssvy7ZpQQasQ==")
        )

        file_set = Wayfinder.for(unpreserved_resource).file_sets.first
        expect(file_set.primary_file.checksum).to be_present

        po = Wayfinder.for(file_set).preservation_object
        expect(po).to be_present
        expect(po.binary_node_for(file_set.primary_file).checksum.first.md5).to eq file_set.primary_file.checksum.first.md5
      end
    end

    # To ensure we're sending the file we know about we send the MD5 we
    # calculated during characterization, so this makes sure that if we don't have
    # it when preservation initially runs that it still preserves eventually.
    # This would only happen if a resource is ingested directly to complete, or
    # a file is added to a complete resource.
    context "when Characterization runs after preservation", run_real_characterization: true do
      with_queue_adapter :test
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }
      context "for non-image files" do
        let(:file2) { fixture_file_upload("files/ephemera.csv", "text/csv") }
        it "uploads the binary nodes" do
          allow(storage_adapter).to receive(:upload).and_call_original

          unpreserved_resource
          # Runs the preservation jobs and preserve children job.
          perform_enqueued_jobs(only: [PreserveResourceJob, PreserveChildrenJob]) do
            perform_enqueued_jobs(only: PreserveResourceJob)
          end
          # Runs characterization/derivatives
          perform_enqueued_jobs do
            perform_enqueued_jobs(only: CharacterizationJob)
          end

          expect(storage_adapter).to have_received(:upload).with(
            # MD5 of the CSV.
            hash_including(md5: "QyXPzJmbg0ehHmjCjXn8/Q==")
          )
        end
      end
    end

    context "when preserving a Scanned Resource with an attached Selene Resource" do
      let(:resource) do
        FactoryBot.create_for_repository(:complete_scanned_resource_with_selene_resource,
                                         source_metadata_identifier: "991234563506421")
      end
      let(:change_set) { ChangeSet.for(resource) }
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:google_cloud_storage) }


      it "saves Selene files nested under the parent scanned resource and FileSet" do
        preserver.preserve!
        file_set = resource.decorate.file_sets.first
        selene = file_set.decorate.members.first
        selene_file_set = selene.decorate.file_sets.first
        path = "#{Figgy.config['disk_preservation_path']}/#{resource.id}/data/#{file_set.id}/data/#{selene.id}/data/#{selene_file_set.id}/#{selene_file_set.id}.json"

        expect(File.exist?(path)).to be true
      end
    end
  end
end
