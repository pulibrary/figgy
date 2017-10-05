# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BulkIngestService do
  subject(:ingester) { described_class.new(change_set_persister: change_set_persister, logger: logger) }
  let(:logger) { Logger.new(nil) }
  let(:query_service) { metadata_adapter.query_service }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) do
    PlumChangeSetPersister.new(
      metadata_adapter: metadata_adapter,
      storage_adapter: storage_adapter
    )
  end
  describe '#attach_dir' do
    context 'with a set of LAE images' do
      let(:barcode1) { '32101075851400' }
      let(:barcode2) { '32101075851418' }
      let(:lae_dir) { Rails.root.join('spec', 'fixtures', 'lae') }
      let(:folder1) { FactoryGirl.create_for_repository(:ephemera_folder, barcode: [barcode1]) }
      let(:folder2) { FactoryGirl.create_for_repository(:ephemera_folder, barcode: [barcode2]) }
      before do
        folder1
        folder2
      end

      it 'attaches the files' do
        ingester.attach_each_dir(base_directory: lae_dir, property: :barcode, file_filter: '.tif')

        reloaded1 = query_service.find_by(id: folder1.id)
        reloaded2 = query_service.find_by(id: folder2.id)

        expect(reloaded1.member_ids.length).to eq 1
        expect(reloaded2.member_ids.length).to eq 2
      end
    end
  end
end
