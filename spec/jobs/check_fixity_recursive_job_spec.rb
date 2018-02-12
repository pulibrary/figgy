# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CheckFixityRecursiveJob do
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
  let(:file2) { fixture_file_upload('files/example.tif', 'image/tiff') }
  let(:resource) { FactoryBot.build(:scanned_resource) }
  let(:resource2) { FactoryBot.build(:scanned_resource) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
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

    # don't want this to actually run recursively forever
    allow_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).and_return(true)
  end

  describe "#find_next_file_to_check" do
    it 'finds the file set least-recently-updated' do
      described_class.perform_now
      file_set = query_service.find_members(resource: output).first
      file_set2 = query_service.find_members(resource: output2).first
      expect(file_set.original_file.fixity_success).to be nil
      expect(file_set2.original_file.fixity_success).to eq 1
    end
  end

  describe "#perform" do
    let(:job_instance) { described_class.new }

    it 'recurses' do
      expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later)
      job_instance.perform
    end

    it 'saves the file_set' do
      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      fs = query_service.find_members(resource: output2).first
      expect(fs.original_file.fixity_success).not_to be 1
      job_instance.perform
      fs = query_service.find_members(resource: output2).first
      expect(fs.original_file.fixity_success).to be 1
    end
  end
end
