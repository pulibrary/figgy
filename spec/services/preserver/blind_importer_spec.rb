# frozen_string_literal: true

require "rails_helper"

RSpec.describe Preserver::BlindImporter do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:query_service) { ChangeSetPersister.default.query_service }
  let(:persister) { ChangeSetPersister.default.metadata_adapter.persister }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:importer) { described_class.new }
  with_queue_adapter :inline
  before do
    stub_ezid(shoulder: shoulder, blade: blade)
  end
  describe ".import" do
    it "can import arbitrarily deep" do
      volume = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file, file2])
      mvw = FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: [volume.id], run_callbacks: true)

      # Wipe everything
      Blacklight.default_index.connection.delete_by_query("*:*")
      Blacklight.default_index.connection.commit
      query_service.resources.delete
      FileUtils.rm_rf(Figgy.config["repository_path"])

      # MVW Ingested
      mvw_reloaded = described_class.import(id: mvw.id, change_set_persister: ChangeSetPersister.default)
      expect(mvw_reloaded.id).to eq mvw.id
      # Volume Ingested
      volumes = query_service.find_members(resource: mvw_reloaded)
      expect(volumes.length).to eq 1
      reloaded_volume = volumes.first
      expect(reloaded_volume.id).to eq volume.id
      # Files Ingested
      file_sets = query_service.find_members(resource: reloaded_volume)
      expect(file_sets.length).to eq 2
      # Binary Files Exist
      file_set1 = file_sets.first
      expect { Valkyrie::StorageAdapter.find_by(id: file_set1.original_file.file_identifiers.first) }.not_to raise_error
      file_set2 = file_sets.last
      expect { Valkyrie::StorageAdapter.find_by(id: file_set2.original_file.file_identifiers.first) }.not_to raise_error
    end
    it "imports a preserved resource given an ID" do
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
      children = query_service.find_members(resource: resource)

      # Delete them without running callbacks which clean up from disk.
      persister.delete(resource: resource)
      children.each do |child|
        persister.delete(resource: child)
        child.file_metadata.each do |metadata|
          metadata.file_identifiers.each do |identifier|
            Valkyrie::StorageAdapter.delete(id: identifier)
          end
        end
      end

      output = described_class.import(id: resource.id, change_set_persister: ChangeSetPersister.default)
      expect(output.id).to eq resource.id
      expect(output.member_ids.length).to eq 1
      file_sets = query_service.find_members(resource: output)

      expect(file_sets.length).to eq 1
      expect(file_sets[0].id).to eq children.first.id
      file_set = file_sets[0]
      # Ensure the file actually got moved over.
      Valkyrie::StorageAdapter.find_by(id: file_set.original_file.file_identifiers.first)
      expect(file_set.derivative_files.length).to eq 1
    end
    it "imports everything it can, even if a member didn't get preserved for some reason" do
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
      children = query_service.find_members(resource: resource)

      # Delete them without running callbacks which clean up from disk.
      persister.delete(resource: resource)
      children.each do |child|
        persister.delete(resource: child)
        child.file_metadata.each do |metadata|
          metadata.file_identifiers.each do |identifier|
            Valkyrie::StorageAdapter.delete(id: identifier)
          end
        end
      end
      FileUtils.rm_rf(Pathname.new(Figgy.config["disk_preservation_path"]).join(resource.id.to_s).join("data").join(children.first.id.to_s))

      output = described_class.import(id: resource.id, change_set_persister: ChangeSetPersister.default)
      expect(output.id).to eq resource.id
      expect(output.member_ids.length).to eq 0
    end
    context "when asked to import a resource that isn't preserved" do
      it "raises a Valkyrie::Persistence::ObjectNotFoundError" do
        resource = FactoryBot.create_for_repository(:pending_scanned_resource)

        expect { described_class.import(id: resource.id, change_set_persister: ChangeSetPersister.default) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
