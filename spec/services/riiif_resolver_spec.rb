# frozen_string_literal: true

require "rails_helper"

RSpec.describe RiiifResolver do
  with_queue_adapter :inline
  subject(:resolver) { described_class.new }
  describe "#pattern" do
    context "when given an ID" do
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      let(:query_service) { metadata_adapter.query_service }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
      it "returns the attached file path" do
        resource = change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
        file_set = query_service.find_members(resource: resource).first
        file = Valkyrie::StorageAdapter.find_by(id: file_set.derivative_file.file_identifiers.first)

        expect(resolver.pattern(file_set.id.to_s)).to eq file.io.path
      end
    end
  end
end
