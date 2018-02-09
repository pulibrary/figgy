# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CheckFixityRecursiveJob do
  let(:file_set1) do
    FactoryBot.create_for_repository(
      :file_set,
      id: 'First',
      file_metadata: [FileMetadata.new]
    )
  end
  let(:file_metadata1) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: 'image/tiff'
    )
  end

  let(:file_set2) do
    FactoryBot.create_for_repository(
      :file_set,
      id: 'Second',
      file_metadata: [file_metadata2]
    )
  end
  let(:file_metadata2) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: 'image/tiff',
    )
  end

  let(:file_metadata3) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: 'image/tiff',
      fixity_success: 1
    )
  end

  before do
    # don't want this to actually run recursively forever
    allow_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).and_return(true)
  end

  # Why are we testing the private method?
  # I tried to test that the file set was receiving :run_fixity
  # but although that was happening, the spec wasn't reading it, I think
  # because the object found was not in the same memory location as the spec object.
  # This will all be moot soon because we're replacing this method with a custom query
  describe "#find_next_file_to_check" do
    before do
      file_set1
      Timecop.freeze(Time.now.utc - 5.minutes) do
        file_set2
      end
    end

    it 'finds the file set least-recently-updated' do
      expect(described_class.new.send(:find_next_file_to_check).id).to eq file_set2.id
    end
  end

  describe "#perform" do
    let(:job_instance) { described_class.new }
    before do
      file_set2
      allow(file_set2).to receive(:run_fixity).and_return(file_metadata3)
      allow(job_instance).to receive(:find_next_file_to_check).and_return(file_set2)
    end

    it 'recurses' do
      expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later)
      job_instance.perform
    end

    it 'saves the file_set' do
      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      fs = query_service.find_by(id: file_set2.id)
      expect(fs.original_file.fixity_success).not_to be 1
      job_instance.perform
      fs = query_service.find_by(id: file_set2.id)
      expect(fs.original_file.fixity_success).to be 1
    end
  end
end
