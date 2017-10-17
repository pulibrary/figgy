# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IngestDiskFolderJob do
  describe '#perform' do
    context 'with a directory of Scanned TIFFs' do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join('spec', 'fixtures', 'ingest_multi') }
      let(:bib) { '4609321' }
      let(:local_id) { 'cico:xyz' }
      let(:replaces) { 'pudl0001/4609321/331' }
      let(:query_service) { metadata_adapter.query_service }
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

      before do
        stub_bibdata(bib_id: '4609321')
        stub_ezid(shoulder: "99999/fk4", blade: "4609321")
      end

      it 'ingests the resources' do
        coll = FactoryGirl.create_for_repository(:collection)

        ingest_service = instance_double(BulkIngestService)
        allow(ingest_service).to receive(:attach_dir)
        allow(BulkIngestService).to receive(:new).and_return(ingest_service)

        described_class.perform_now(
          directory: multi_dir,
          source_metadata_identifier: bib,
          local_identifier: local_id,
          collection: coll
        )

        expect(ingest_service).to have_received(:attach_dir).with(
          base_directory: multi_dir,
          file_filter: '.tif',
          source_metadata_identifier: bib,
          local_identifier: local_id,
          collection: coll
        )
      end
    end
  end
end
