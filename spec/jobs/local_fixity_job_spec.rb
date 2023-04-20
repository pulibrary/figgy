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
  let(:file_set) { scanned_resource.decorate.file_sets.first }
  let(:file_set_id) { file_set.id }

  let(:file_metadata2) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: "image/tiff"
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
      expect(event).to be_successful
      expect(event.child_id).to eq fs.original_file.id
      expect(event.child_property).to eq "file_metadata"
    end

    context "with a preservation file and an intermediate file" do
      let(:file) { fixture_file_with_use("files/example.tif", "image/tiff", Valkyrie::Vocab::PCDMUse.PreservationFile) }

      it "creates a local_fixity Event for both files" do
        IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"), file_set_id: file_set.id)
        described_class.perform_now(file_set_id)
        events = query_service.find_all_of_model(model: Event)
        expect(events.to_a.length).to eq 2
      end
    end

    context "when the new checksum doesn't match" do
      before do
        fs = query_service.find_by(id: file_set_id)
        filename = fs.primary_file.file_identifiers[0].to_s.gsub("disk://", "")
        new_file = File.join(fixture_path, "files/color-landscape.tif")
        FileUtils.cp(new_file, filename)
        allow(Honeybadger).to receive(:notify)
        allow(RestoreLocalFixityJob).to receive(:perform_later)
      end

      context "when the previous event had status: repairing" do
        it "creates a failed event and notifies Honeybadger" do
          FactoryBot.create(:local_fixity_repairing, resource_id: file_set_id, child_id: file_set.original_file.id)

          described_class.perform_now(file_set_id)
          fs = query_service.find_by(id: file_set_id)

          events = query_service.find_all_of_model(model: Event)
          expect(events.to_a.length).to eq 2
          event = events.find(&:current?)
          expect(event.type).to eq "local_fixity"
          expect(event.resource_id).to eq fs.id
          expect(event).to be_failed
          expect(JSON.parse(event.message).keys).to eq [
            "id", "internal_resource", "created_at", "updated_at",
            "new_record", "sha256", "md5", "sha1"
          ]
          expect(Honeybadger).to have_received(:notify)
          expect(RestoreLocalFixityJob).not_to have_received(:perform_later)
        end
      end

      context "when the previous event had any other status" do
        it "creates a repairing event, notifies Honeybadger, and starts a restore job" do
          FactoryBot.create(:local_fixity_success, resource_id: file_set_id, child_id: file_set.original_file.id)
          described_class.perform_now(file_set_id)
          fs = query_service.find_by(id: file_set_id)

          events = query_service.find_all_of_model(model: Event)
          expect(events.to_a.length).to eq 2
          event = events.find(&:current?)
          expect(event.type).to eq "local_fixity"
          expect(event.resource_id).to eq fs.id
          expect(event).to be_repairing
          expect(JSON.parse(event.message).keys).to eq [
            "id", "internal_resource", "created_at", "updated_at",
            "new_record", "sha256", "md5", "sha1"
          ]
          expect(Honeybadger).to have_received(:notify)
          expect(RestoreLocalFixityJob).to have_received(:perform_later)
        end
      end
    end

    context "with a preservation file and an intermediate file and one checksum doesn't match" do
      let(:file) { fixture_file_with_use("files/example.tif", "image/tiff", Valkyrie::Vocab::PCDMUse.PreservationFile) }
      before do
        allow(RestoreLocalFixityJob).to receive(:perform_later)
      end

      context "when the previous event had status: repairing" do
        it "creates one success event and failed event and notifies Honeybadger" do
          FactoryBot.create(:local_fixity_repairing, resource_id: file_set_id, child_id: file_set.primary_file.id)
          allow(Honeybadger).to receive(:notify)
          IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"), file_set_id: file_set.id)

          fs = query_service.find_by(id: file_set_id)
          filename = fs.primary_file.file_identifiers[0].to_s.gsub("disk://", "")
          new_file = File.join(fixture_path, "files/color-landscape.tif")
          FileUtils.cp(new_file, filename)
          described_class.perform_now(file_set_id)

          events = query_service.find_all_of_model(model: Event)
          expect(events.to_a.length).to eq 3
          current_events = events.select(&:current?)
          expect(current_events.map(&:status)).to contain_exactly("FAILURE", "SUCCESS")
          event = current_events.find(&:failed?)
          expect(event.type).to eq "local_fixity"
          expect(event.resource_id).to eq fs.id
          expect(event.child_id).to eq fs.primary_file.id
          expect(JSON.parse(event.message).keys).to eq [
            "id", "internal_resource", "created_at", "updated_at",
            "new_record", "sha256", "md5", "sha1"
          ]
          expect(Honeybadger).to have_received(:notify)
          expect(RestoreLocalFixityJob).not_to have_received(:perform_later)
        end
      end

      context "when the previous event had any other status" do
        it "creates one success event and repairing event, notifies Honeybadger, and starts a restore job" do
          FactoryBot.create(:local_fixity_failure, resource_id: file_set_id, child_id: file_set.primary_file.id)
          allow(Honeybadger).to receive(:notify)
          IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"), file_set_id: file_set.id)

          fs = query_service.find_by(id: file_set_id)
          filename = fs.primary_file.file_identifiers[0].to_s.gsub("disk://", "")
          new_file = File.join(fixture_path, "files/color-landscape.tif")
          FileUtils.cp(new_file, filename)
          described_class.perform_now(file_set_id)

          events = query_service.find_all_of_model(model: Event)
          expect(events.to_a.length).to eq 3
          current_events = events.select(&:current?)
          expect(current_events.map(&:status)).to contain_exactly("REPAIRING", "SUCCESS")
          event = current_events.find(&:repairing?)
          expect(event.type).to eq "local_fixity"
          expect(event.resource_id).to eq fs.id
          expect(event.child_id).to eq fs.primary_file.id
          expect(JSON.parse(event.message).keys).to eq [
            "id", "internal_resource", "created_at", "updated_at",
            "new_record", "sha256", "md5", "sha1"
          ]
          expect(Honeybadger).to have_received(:notify)
          expect(RestoreLocalFixityJob).to have_received(:perform_later)
        end
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

    context "when an current Event already exists" do
      it "sets that Event current property to false" do
        described_class.perform_now(file_set_id)
        first_event = query_service.find_all_of_model(model: Event).first
        expect(first_event).to be_current

        described_class.perform_now(file_set_id)
        events = query_service.find_all_of_model(model: Event)
        event1 = events.find { |e| e.id == first_event.id }
        event2 = events.find { |e| e.id != first_event.id }
        expect(event1).not_to be_current
        expect(event2).to be_current
      end
    end
  end
end
