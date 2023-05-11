# frozen_string_literal: true
require "rails_helper"

RSpec.describe RepairCloudFixity do
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:metadata_adapter) { change_set_persister.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:persister) { metadata_adapter.persister }

  before do
    allow(CloudFixity::FixityRequestor).to receive(:queue_resource_check!)
  end

  context "when a metadata node has failed fixity" do
    it "re-preserves the metadata file" do
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, title: "Preserved Resource Title")
      Preserver.for(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister).preserve!
      preservation_object = query_service.find_all_of_model(model: PreservationObject).first
      # change the metadata so it doesn't match what's been preserved
      resource = query_service.find_by(id: resource.id)
      resource.title = ["Unexpected Title"]
      persister.save(resource: resource)
      failed_event = FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: preservation_object.id, child_property: "metadata_node")

      preserver_double = instance_double(Preserver)
      allow(preserver_double).to receive(:preserve!)
      allow(Preserver).to receive(:for).and_return(preserver_double)
      described_class.run(event: failed_event)
      expect(Preserver).not_to have_received(:for).with(force_preservation: true, change_set: anything, change_set_persister: anything)
      expect(preserver_double).to have_received(:preserve!)
    end
  end

  context "when a binary node has failed fixity" do
    with_queue_adapter :inline

    before do
      stub_ezid(shoulder: "99999/fk4", blade: "9946093213506421")
    end

    context "when the local file matches its recorded checksum" do
      it "re-preserves the local file" do
        file = fixture_file_upload("files/example.tif")
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, title: "Preserved Resource Title", files: [file])
        file_set = resource.decorate.file_sets.first
        Preserver.for(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister).preserve!
        preservation_object = query_service.find_all_of_model(model: PreservationObject).find { |po| po.preserved_object_id == file_set.id }
        failed_event = FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: preservation_object.id, child_property: "binary_nodes")

        preserver_double = instance_double(Preserver)
        allow(preserver_double).to receive(:preserve!)
        allow(Preserver).to receive(:for).and_return(preserver_double)
        described_class.run(event: failed_event)
        expect(Preserver).to have_received(:for).with(force_preservation: true, change_set: anything, change_set_persister: anything)
        expect(preserver_double).to have_received(:preserve!)
        expect(CloudFixity::FixityRequestor).to have_received(:queue_resource_check!).with(id: file_set.id.to_s)
      end
    end

    context "when the local file does not match its recorded checksum" do
      it "creates a failure event" do
        file = fixture_file_upload("files/example.tif")
        resource = change_set_persister.save(change_set: ChangeSet.for(FactoryBot.create(:complete_scanned_resource, files: [file])))
        file_set = resource.decorate.file_sets.first
        file_identifier = file_set.original_file.file_identifiers.first
        preservation_object = query_service.find_all_of_model(model: PreservationObject).find { |po| po.preserved_object_id == file_set.id }
        repairing_event = FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: preservation_object.id, child_property: "binary_nodes",
                                                                                child_id: preservation_object.binary_nodes.first.id)

        modify_file(file_identifier)

        # Mock repairing local fixity (called in the LocalFixityJob)
        allow(RepairLocalFixityJob).to receive(:perform_later)
        allow(Preserver).to receive(:for)

        described_class.run(event: repairing_event)
        current_events = Wayfinder.for(preservation_object).current_cloud_fixity_events
        expect(current_events.count).to eq 1
        expect(current_events.first).to be_failed
        expect(Preserver).not_to have_received(:for).with(force_preservation: true, change_set: anything, change_set_persister: anything)
      end
    end

    context "with an ArchivalMediaCollection resource with a fileset that has a good preservation file and a bad intermediate file" do
      let(:collection_cid) { "C0652" }
      let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
      let(:user) { FactoryBot.create(:admin) }

      before do
        stub_findingaid(pulfa_id: "C0652")
        stub_findingaid(pulfa_id: "C0652_c0377")
      end

      it "creates a failure event" do
        IngestArchivalMediaBagJob.perform_now(collection_component: collection_cid, bag_path: bag_path, user: user)
        resources = query_service.find_all_of_model(model: ScannedResource)
        resource = resources.find { |r| r.decorate.file_sets.present? }
        file_set = resource.decorate.file_sets.first

        # Complete the resource
        cs = ChangeSet.for(resource)
        cs.validate(state: "complete")
        ChangeSetPersister.default.save(change_set: cs)

        preservation_object = query_service.find_all_of_model(model: PreservationObject).find { |po| po.preserved_object_id == file_set.id }
        repairing_event = FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: preservation_object.id, child_property: "binary_nodes",
                                                                                child_id: preservation_object.binary_nodes.first.id)

        # Modify the intermediate or preservation file
        file_metadata = file_set.file_metadata.reverse.find do |r|
          r.use.include?(Valkyrie::Vocab::PCDMUse.IntermediateFile) || r.use.include?(Valkyrie::Vocab::PCDMUse.PreservationFile)
        end
        modify_file(file_metadata.file_identifiers.first)

        # Mock repairing local fixity (called in the LocalFixityJob)
        allow(RepairLocalFixityJob).to receive(:perform_later)
        allow(Preserver).to receive(:for)

        described_class.run(event: repairing_event)
        current_events = Wayfinder.for(preservation_object).current_cloud_fixity_events
        expect(current_events.count).to eq 1
        expect(current_events.first).to be_failed
        expect(Preserver).not_to have_received(:for).with(force_preservation: true, change_set: anything, change_set_persister: anything)
      end
    end
  end
end
