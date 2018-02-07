# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

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
      fixity_last_run_date: Time.now.utc - 5.minutes
    )
  end

  let(:file_set3) do
    FactoryBot.create_for_repository(
      :file_set,
      id: 'Third',
      file_metadata: [file_metadata3]
    )
  end
  let(:file_metadata3) do
    FileMetadata.new(
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: 'image/tiff',
      fixity_last_run_date: Time.now.utc,
      fixity_success: 1
    )
  end

  before do
    file_set2
    # don't want this to actually run recursively forever
    allow_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).and_return(true)
  end

  describe "when all file sets have had a fixity check" do
    before do
      file_set3
    end

    # I tried to test that file_set1 was receiving :run_fixity
    # but although that was happening, the spec wasn't reading it, I think
    # because the object found was not in the same memory location as the spec object.
    # so have to test the private method instead.
    it 'finds the object least-recently-updated' do
      expect(described_class.new.send(:find_next_file_to_check).id).to eq file_set2.id
    end
  end

  describe "when not all file sets have had a fixity check" do
    before do
      file_set1
    end

    it 'compares fixity_last_run_date to created_at' do
      expect(described_class.new.send(:find_next_file_to_check).id).to eq file_set2.id
    end
  end

  describe "the job" do
    let(:job_instance) { described_class.new }
    before do
      allow(file_set2).to receive(:run_fixity).and_return(file_metadata3)
      allow(job_instance).to receive(:find_next_file_to_check).and_return(file_set2)
    end

    it 'recurses' do
      expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later)
      job_instance.perform
    end

    it 'saves the file_set' do
      job_instance.perform
      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      fs = query_service.find_by(id: file_set2.id)
      expect(fs.created_at).to be < fs.updated_at
    end
  end
end
