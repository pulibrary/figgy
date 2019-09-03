# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetsSortedByUpdated do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file3) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.build(:scanned_resource) }
  let(:resource2) { FactoryBot.build(:scanned_resource) }
  let(:resource3) { FactoryBot.build(:scanned_resource) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:change_set) { ScannedResourceChangeSet.new(resource) }
  let(:change_set2) { ScannedResourceChangeSet.new(resource2) }
  let(:change_set3) { ScannedResourceChangeSet.new(resource3) }
  let(:output) do
    change_set.files = [file]
    change_set_persister.save(change_set: change_set)
  end
  let(:output2) do
    change_set2.files = [file2]
    change_set_persister.save(change_set: change_set2)
  end
  let(:output3) do
    change_set3.files = [file3]
    change_set_persister.save(change_set: change_set3)
  end
  before do
    # they have to be saved to come out in the query
    Timecop.freeze(Time.now.utc - 10.minutes) do
      query_service.find_members(resource: output).first
    end
    Timecop.freeze(Time.now.utc - 5.minutes) do
      query_service.find_members(resource: output2).first
    end
    query_service.find_members(resource: output3).first
  end

  describe "#file_sets_sorted_by_updated" do
    it "finds least recently updated file sets with the given limit" do
      result = query_service.custom_queries.file_sets_sorted_by_updated
      expect(result.count).to eq 3
      expect(result.next.id.to_s).to eq query_service.find_members(resource: output).first.id.to_s
      expect(result.next.id.to_s).to eq query_service.find_members(resource: output2).first.id.to_s
      expect(result.next.id.to_s).to eq query_service.find_members(resource: output3).first.id.to_s
    end

    it "returns a lazy enumerator" do
      result = query_service.custom_queries.file_sets_sorted_by_updated
      expect(result).to be_a Enumerator::Lazy
    end
  end

  it "finds most recently updated file sets with the given limit" do
    result = query_service.custom_queries.file_sets_sorted_by_updated(sort: "desc", limit: 2)
    expect(result.count).to eq 2
    expect(result.next.id.to_s).to eq query_service.find_members(resource: output3).first.id.to_s
    expect(result.next.id.to_s).to eq query_service.find_members(resource: output2).first.id.to_s
  end
end
