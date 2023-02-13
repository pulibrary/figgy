# frozen_string_literal: true
require "rails_helper"

RSpec.describe CheckFixityRecursiveJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.build(:scanned_resource) }
  let(:resource2) { FactoryBot.build(:scanned_resource) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:change_set) { ScannedResourceChangeSet.new(resource) }
  let(:change_set2) { ScannedResourceChangeSet.new(resource2) }
  let(:output) do
    change_set.files = [file]
    change_set_persister.save(change_set: change_set)
  end
  let(:output2) do
    change_set2.files = [file2]
    change_set_persister.save(change_set: change_set2)
  end

  before do
    # it has to be charaterized to compare the checksums,
    # and it has to be saved to characterize
    file_set = query_service.find_members(resource: output).first
    CharacterizationJob.perform_now(file_set.id.to_s)
    Timecop.freeze(Time.now.utc - 5.minutes) do
      file_set2 = query_service.find_members(resource: output2).first
      CharacterizationJob.perform_now(file_set2.id.to_s)
    end
  end

  describe "#perform" do
    let(:job_instance) { described_class.new }

    it "updates only the least-recently-updated file_set" do
      pending "This job currently is not running, and is going to be rewritten. See https://github.com/pulibrary/figgy/issues/5554"
      file_set2 = query_service.find_members(resource: output2).first
      expect(file_set2.original_file.fixity_success).to be nil

      described_class.new.perform
      file_set2 = query_service.find_members(resource: output2).first
      expect(file_set2.original_file.fixity_success).to be 1
      file_set = query_service.find_members(resource: output).first
      expect(file_set.original_file.fixity_success).to be nil
    end

    it "recurses" do
      expect { described_class.new.perform }.to have_enqueued_job(described_class)
    end
  end
end
