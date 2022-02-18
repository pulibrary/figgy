# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindCloudFixity do
  with_queue_adapter :inline
  subject(:query) { described_class.new(query_service: query_service) }

  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
  let(:file_set) { resource.decorate.file_sets.first }
  let(:event) { FactoryBot.create_for_repository(:event, resource_id: file_set.id) }
  let(:event2) { FactoryBot.create_for_repository(:event, resource_id: file_set.id) }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    event
    event2
  end

  describe "#find_cloud_fixity_checks" do
    let(:status) { "SUCCESS" }

    it "can find file_sets for files stored in cloud services with successful fixity checks" do
      output = query.find_cloud_fixity(status: status)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include event.id
      expect(output_ids).to include event2.id
    end

    context "when querying for failed fixity checks" do
      let(:status) { "FAILURE" }
      let(:event3) { FactoryBot.create_for_repository(:event, status: status, resource_id: file_set.id) }

      before do
        event3
      end

      it "can find file_sets for files stored in cloud services with failed fixity checks" do
        output = query.find_cloud_fixity(status: status)
        expect(output.length).to eq 1
        output_ids = output.map(&:id)
        expect(output_ids).to include event3.id
      end
    end

    it "limits the number of results" do
      5.times do
        FactoryBot.create_for_repository(:event)
      end

      output = query.find_cloud_fixity(limit: 2, status: status)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include event.id
      expect(output_ids).to include event2.id
    end

    it "sorts by either ascending or descending order" do
      output = query.find_cloud_fixity(status: status)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event.id
      expect(output.last.id).to eq event2.id

      output = query.find_cloud_fixity(sort: "DESC", status: status)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event2.id
      expect(output.last.id).to eq event.id
    end

    it "sorts by either the time of the last update or the resource creation" do
      output = query.find_cloud_fixity(order_by_property: "created_at", status: status)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event.id
      expect(output.last.id).to eq event2.id

      cs = EventChangeSet.new(event2)
      cs.validate(message: "updated")
      change_set_persister.save(change_set: cs)

      output2 = query.find_cloud_fixity(sort: "DESC", status: status)
      expect(output2.length).to eq 2
      expect(output2.first.id).to eq event2.id
      expect(output2.last.id).to eq event.id
    end
  end
end
