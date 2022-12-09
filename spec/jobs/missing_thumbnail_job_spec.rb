# frozen_string_literal: true
require "rails_helper"

RSpec.describe MissingThumbnailJob do
  describe ".perform" do
    let(:file) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
    let(:resource) do
      sr = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      reloaded_resource = query_service.find_by(id: sr.id)
      change_set = ScannedResourceChangeSet.new(reloaded_resource)
      change_set.thumbnail_id = nil
      change_set_persister.save(change_set: change_set)
    end
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
    let(:query_service) { metadata_adapter.query_service }
    let(:updated_resource) { query_service.find_by(id: Valkyrie::ID.new(resource.id)) }
    let(:file_sets) { query_service.find_members(resource: resource) }

    before do
      described_class.perform_now(resource.id.to_s)
    end

    it "sets the thumbnail for the resource" do
      expect(updated_resource.thumbnail_id).not_to be_empty
      expect(updated_resource.thumbnail_id.first.to_s).to eq file_sets.first.thumbnail_id.to_s
    end

    context "when the resource is a multi-volume work" do
      let(:file) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
      let(:member) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member.id]) }
      it "sets the thumbnail using the first member of the multi-volume work" do
        expect(updated_resource.thumbnail_id).not_to be_empty
        expect(updated_resource.thumbnail_id.first.to_s).to eq member.thumbnail_id.first.to_s
      end
    end

    context "when the resource has no filesets" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:logger) { instance_double(Logger) }
      it "has no thumbnail" do
        expect(updated_resource.thumbnail_id).to be nil
      end
    end
  end
end
