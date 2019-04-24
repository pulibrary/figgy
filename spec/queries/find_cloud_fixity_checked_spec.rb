# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindCloudFixityChecked do
  with_queue_adapter :inline
  subject(:query) { described_class.new(query_service: query_service) }

  let(:file_identifiers) do
    [
      Valkyrie::ID.new("shrine://test-id")
    ]
  end
  let(:file_metadata) { FileMetadata.new(fixity_success: 1, file_identifiers: file_identifiers) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata) }
  let(:file_metadata2) { FileMetadata.new(fixity_success: 0, file_identifiers: file_identifiers) }
  let(:file_set2) { FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata2) }
  let(:file_set3) { FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata) }
  # let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }

  describe "#find_cloud_fixity_checks" do
    before do
      file_set
      file_set2
      file_set3
    end

    it "can find file_sets for files stored in cloud services with successful fixity checks" do
      output = query.find_cloud_fixity_checked
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include file_set.id
      expect(output_ids).to include file_set3.id
    end

    it "limits the number of results" do
      5.times do
        FactoryBot.create_for_repository(:file_set, file_metadata: file_metadata)
      end

      output = query.find_cloud_fixity_checked(limit: 2)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include file_set.id
      expect(output_ids).to include file_set3.id
    end

    it "sorts by either ascending or descending order" do
      output = query.find_cloud_fixity_checked
      expect(output.length).to eq 2
      expect(output.first.id).to eq file_set.id
      expect(output.last.id).to eq file_set3.id

      output = query.find_cloud_fixity_checked(sort: "DESC")
      expect(output.length).to eq 2
      expect(output.first.id).to eq file_set3.id
      expect(output.last.id).to eq file_set.id
    end

    it "sorts by either the time of the last update or the resource creation" do
      output = query.find_cloud_fixity_checked(order_by_property: "created_at")
      expect(output.length).to eq 2
      expect(output.first.id).to eq file_set.id
      expect(output.last.id).to eq file_set3.id

      cs = FileSetChangeSet.new(file_set3)
      cs.validate(label: "updated")
      change_set_persister.save(change_set: cs)

      output2 = query.find_cloud_fixity_checked(sort: "DESC")
      expect(output2.length).to eq 2
      expect(output2.first.id).to eq file_set3.id
      expect(output2.last.id).to eq file_set.id
    end
  end
end
