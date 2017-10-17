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

  describe '#attach_each_dir' do
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

  describe '#attach_dir' do
    context 'with a directory of Scanned TIFFs' do
      let(:logger) { Logger.new(nil) }
      let(:single_dir) { Rails.root.join('spec', 'fixtures', 'ingest_single') }
      let(:bib) { '4609321' }
      let(:local_id) { 'cico:xyz' }
      let(:replaces) { 'pudl0001/4609321/331' }

      before do
        stub_bibdata(bib_id: '4609321')
        stub_ezid(shoulder: "99999/fk4", blade: "4609321")
      end

      it 'ingests the resources' do
        coll = FactoryGirl.create_for_repository(:collection)

        ingester.attach_dir(
          base_directory: single_dir,
          file_filter: '.tif',
          source_metadata_identifier: bib,
          local_identifier: local_id,
          collection: coll
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1

        resource = decorated_collection.members.to_a.first
        expect(resource.source_metadata_identifier).to include(bib)
        expect(resource.local_identifier).to include(local_id)
      end
    end

    context 'with a directory of subdirectories of TIFFs' do
      let(:logger) { Logger.new(nil) }
      let(:multi_dir) { Rails.root.join('spec', 'fixtures', 'ingest_multi') }
      let(:bib) { '4609321' }
      let(:local_id) { 'cico:xyz' }
      let(:replaces) { 'pudl0001/4609321/331' }
      let(:coll) { FactoryGirl.create(:collection) }

      before do
        stub_bibdata(bib_id: '4609321')
        stub_ezid(shoulder: "99999/fk4", blade: "4609321")
      end

      it 'ingests the resources', bulk: true do
        coll = FactoryGirl.create_for_repository(:collection)

        ingester.attach_dir(
          base_directory: multi_dir,
          file_filter: '.tif',
          source_metadata_identifier: bib,
          local_identifier: local_id,
          collection: coll
        )

        updated_collection = query_service.find_by(id: coll.id)
        decorated_collection = updated_collection.decorate
        expect(decorated_collection.members.to_a.length).to eq 1

        resource = decorated_collection.members.to_a.first
        expect(resource).to be_a ScannedResource
        expect(resource.source_metadata_identifier).to include(bib)
        expect(resource.local_identifier).to include(local_id)

        decorated_resource = resource.decorate
        expect(decorated_resource.volumes.length).to eq 2
        child_resource = decorated_resource.volumes.first
        expect(child_resource).to be_a ScannedResource
        expect(child_resource.local_identifier).to include(local_id)
      end
    end

    context 'with invalid property arguments' do
      let(:logger) { instance_double(Logger) }
      let(:single_dir) { Rails.root.join('spec', 'fixtures', 'ingest_single') }
      let(:bib) { '4609321' }
      let(:local_id) { 'cico:xyz' }
      let(:replaces) { 'pudl0001/4609321/331' }

      before do
        allow(logger).to receive(:warn)
        allow(logger).to receive(:info)
        stub_bibdata(bib_id: '4609321')
        stub_ezid(shoulder: "99999/fk4", blade: "4609321")
      end

      it 'does not ingest the resources and logs a warning' do
        ingester.attach_dir(
          base_directory: single_dir,
          property: 'noexist',
          file_filter: '.tif',
          source_metadata_identifier: bib
        )

        expect(logger).to have_received(:warn).with("Failed to find the resource for noexist:ingest_single")
        expect(logger).to have_received(:info).with(/Created the resource/)
      end
    end
  end
end
