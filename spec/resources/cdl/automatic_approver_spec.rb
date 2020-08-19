# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::AutomaticApprover do
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:change_set_persister) { ScannedResourcesController.change_set_persister }
  describe ".run" do
    context "when there's in process CDL items" do
      it "does not approve them" do
        resource = FactoryBot.create_for_repository(:pending_cdl_resource, files: [file])

        described_class.run

        resource = query_service.find_by(id: resource.id)
        expect(resource.state).to eq ["pending"]
      end
    end
    context "when the PDF page count doesn't match the file count" do
      with_queue_adapter :inline
      it "doesn't approve them" do
        resource = FactoryBot.create_for_repository(:pending_cdl_resource, files: [file])
        cs = ChangeSet.for(resource)
        cs.validate(files: [file])
        change_set_persister.save(change_set: cs)

        described_class.run

        resource = query_service.find_by(id: resource.id)
        expect(resource.state).to eq ["pending"]
      end
    end
    context "when there's CDL items with processed files", run_real_derivatives: true, run_real_characterization: true do
      with_queue_adapter :inline
      it "approves them" do
        stub_ezid(shoulder: "99999/fk4", blade: "")
        stub_bibdata(bib_id: "123456")
        User.create!(uid: "skye", email: "skye@princeton.edu")
        User.create!(uid: "zelda", email: "zelda@princeton.edu")
        collection = FactoryBot.create_for_repository(:collection, slug: "cdl", title: "CDL", owners: ["skye", "zelda"])
        resource = FactoryBot.create_for_repository(:pending_cdl_resource, files: [file], member_of_collection_ids: [collection.id], source_metadata_identifier: "123456")

        described_class.run

        resource = query_service.find_by(id: resource.id)
        expect(resource.member_ids.length).to eq 3
        expect(resource.state).to eq ["complete"]
        expect(ActionMailer::Base.deliveries.size).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to eq ["skye@princeton.edu", "zelda@princeton.edu"]
        expect(mail.subject).to eq "CDL Items Complete: 123456"
      end
    end
    context "when the manifest builder fails to generate", run_real_derivatives: true, run_real_characterization: true do
      with_queue_adapter :inline
      it "doesn't approve it" do
        resource = FactoryBot.create_for_repository(:pending_cdl_resource, files: [file])
        allow_any_instance_of(ManifestBuilder).to receive(:build).and_raise("Broken")

        described_class.run

        resource = query_service.find_by(id: resource.id)
        expect(resource.state).to eq ["pending"]
      end
    end
  end
end
