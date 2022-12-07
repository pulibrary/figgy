# frozen_string_literal: true
require "rails_helper"

RSpec.describe LocalFixityJob do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:file_set_id) { scanned_resource.member_ids.first }

  let(:file_metadata2) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: "image/tiff",
      fixity_success: 1
    )
  end

  before do
    scanned_resource
    CharacterizationJob.perform_now(file_set_id.to_s)
  end

  describe "#perform" do
    it "creates a local_fixity Event" do
      described_class.perform_now(file_set_id)
      fs = query_service.find_by(id: file_set_id)

      events = query_service.find_all_of_model(model: Event)
      expect(events.to_a.length).to eq 1
      event = events.first
      expect(event.type).to eq "local_fixity"
      expect(event.resource_id).to eq fs.id
      expect(event.status).to eq "SUCCESS"
    end

    context "when the new checksum doesn't match" do
      before do
        fs = query_service.find_by(id: file_set_id)
        filename = fs.primary_file.file_identifiers[0].to_s.gsub("disk://", "")
        new_file = File.join(fixture_path, "files/color-landscape.tif")
        FileUtils.cp(new_file, filename)
        allow(Honeybadger).to receive(:notify)
      end

      it "creates a failed event and notifies Honeybadger" do
        described_class.perform_now(file_set_id)
        fs = query_service.find_by(id: file_set_id)

        events = query_service.find_all_of_model(model: Event)
        expect(events.to_a.length).to eq 1
        event = events.first
        expect(event.type).to eq "local_fixity"
        expect(event.resource_id).to eq fs.id
        expect(event.status).to eq "FAILURE"
        expect(JSON.parse(event.message).keys).to eq [
          "id", "internal_resource", "created_at", "updated_at",
          "new_record", "sha256", "md5", "sha1"
        ]
        expect(Honeybadger).to have_received(:notify)
      end
    end

    context "when the file set does not exist" do
      let(:file_set_id) { "5f4235a3-53c0-42cc-9ada-564ea554264e" }
      it "logs a warning" do
        allow(Valkyrie.logger).to receive(:warn)
        described_class.perform_now file_set_id

        expect(Valkyrie.logger).to have_received(:warn).with "#{described_class}: Valkyrie::Persistence::ObjectNotFoundError: Failed to find the resource #{file_set_id}"
      end
    end

    context "when FileNotFound on a non-orphaned file set" do
      it "raises a FileNotFound error" do
        allow(Valkyrie::StorageAdapter).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)

        expect { described_class.perform_now(file_set_id) }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end
    end

    context "when FileNotFound on an orphaned file set" do
      it "deletes the fileset" do
        change_set = ChangeSet.for(scanned_resource)
        change_set_persister.delete(change_set: change_set)
        allow(Valkyrie::StorageAdapter).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)

        described_class.perform_now(file_set_id)

        expect { query_service.find_by(id: file_set_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
