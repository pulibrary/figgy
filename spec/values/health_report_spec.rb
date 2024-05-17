# frozen_string_literal: true
require "rails_helper"

RSpec.describe HealthReport do
  describe "#status" do
    context "for a healthy resource" do
      it "returns :healthy" do
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource)

        report = described_class.for(resource)

        expect(report.status).to eq :healthy
      end
    end
    context "for a resource not yet marked complete" do
      it "only checks local fixity and derivatives" do
        resource = FactoryBot.create_for_repository(:pending_scanned_resource)

        report = described_class.for(resource)

        expect(report.checks.length).to eq 2
        expect(report.checks.first.type).to eq "Local Fixity"
      end
    end
    context "for an EphemeraProject" do
      it "only checks itself, not members" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        fs2 = create_file_set(cloud_fixity_status: Event::FAILURE)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [fs1.id, fs2.id])
        project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id])
        create_preservation_object(event_status: Event::SUCCESS, resource_id: project.id, event_type: :cloud_fixity)

        report = described_class.for(project)
        # It would be in_progress if it checked the box for local fixity, and
        # :needs_attention if it checked the box for cloud fixity.
        expect(report.status).to eq :healthy
        expect(report.checks.length).to eq 3
      end
      it "can report if it's repairing" do
        project = FactoryBot.create_for_repository(:ephemera_project)
        create_preservation_object(event_status: Event::REPAIRING, resource_id: project.id, event_type: :cloud_fixity)

        report = described_class.for(project)
        expect(report.status).to eq :repairing
        expect(report.checks.length).to eq 3
      end
    end
    it "can report if it's in progress (no preservation object)" do
      project = FactoryBot.create_for_repository(:ephemera_project)

      report = described_class.for(project)

      expect(report.status).to eq :in_progress
      expect(report.checks.length).to eq 3
    end
    it "can report if it needs attention" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      create_preservation_object(event_status: Event::FAILURE, resource_id: project.id, event_type: :cloud_fixity)

      report = described_class.for(project)
      expect(report.status).to eq :needs_attention
      expect(report.checks.length).to eq 3
    end
    context "for a resource whose local fixity event hasn't run yet" do
      it "returns :in_progress" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :in_progress
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :in_progress
        expect(local_fixity_report.summary).to start_with "Local fixity check is in progress for one or more files."
      end
    end
    context "for a resource with a successful local fixity event" do
      it "returns :healthy" do
        fs1 = create_file_set(cloud_fixity_status: Event::SUCCESS)
        FactoryBot.create(:local_fixity_success, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :healthy
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :healthy
        expect(local_fixity_report.summary).to eq "All local file checksums are verified."
      end
    end
    context "for a resource with a repairing local fixity event" do
      it "returns :repairing" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        FactoryBot.create(:local_fixity_repairing, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :repairing
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :repairing
        expect(local_fixity_report.summary).to start_with "One or more files are in the process of being repaired."
      end
    end
    context "for a resource with a failed local fixity event" do
      it "returns :needs_attention" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        FactoryBot.create(:local_fixity_failure, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :needs_attention
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :needs_attention
        expect(local_fixity_report.summary).to start_with "One or more files failed Local Fixity Checks."

        list = local_fixity_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "#{resource.id}/file_manager"
      end
    end
    context "for a FileSet with a failed local fixity event" do
      it "returns :needs_attention" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        FactoryBot.create(:local_fixity_failure, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(fs1)

        expect(report.status).to eq :needs_attention
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :needs_attention
        expect(local_fixity_report.summary).to start_with "This resource failed Local Fixity Checks."

        list = local_fixity_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "#{resource.id}/file_manager"
      end
    end

    context "for a resource with a failed cloud fixity event on it's metadata" do
      it "returns :needs_attention" do
        fs1 = FactoryBot.create_for_repository(:file_set)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])
        create_preservation_object(resource_id: resource.id, event_status: Event::FAILURE, event_type: :cloud_fixity)

        report = described_class.for(resource)

        expect(report.status).to eq :needs_attention
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :needs_attention
        expect(cloud_fixity_report.summary).to start_with "One or more files failed Cloud Fixity Checks."

        list = cloud_fixity_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "catalog/#{resource.id}"
      end
    end
    context "for a resource with a failed cloud fixity event on it's file set" do
      it "returns :needs_attention" do
        fs1 = create_file_set(cloud_fixity_status: Event::FAILURE)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :needs_attention
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :needs_attention
        expect(cloud_fixity_report.summary).to start_with "One or more files failed Cloud Fixity Checks."

        list = cloud_fixity_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "#{resource.id}/file_manager"
      end
    end
    context "for a FileSet with a failed cloud fixity event" do
      it "returns :needs_attention" do
        fs1 = create_file_set(cloud_fixity_status: Event::FAILURE)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])
        FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource.id)

        report = described_class.for(fs1)

        expect(report.status).to eq :needs_attention
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :needs_attention
        expect(cloud_fixity_report.summary).to start_with "This resource failed Cloud Fixity Checks."

        list = cloud_fixity_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "#{resource.id}/file_manager"
      end
    end
    context "for a resource that hasn't preserved yet" do
      it "returns :in_progress" do
        fs1 = FactoryBot.create_for_repository(:file_set)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :in_progress
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :in_progress
        expect(cloud_fixity_report.summary).to start_with "One or more files are in the process of being preserved."
      end
    end

    context "for a resource with a successful cloud fixity event" do
      it "returns :healthy" do
        fs1 = create_file_set(cloud_fixity_status: Event::SUCCESS)
        FactoryBot.create(:local_fixity_success, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :healthy
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :healthy
        expect(cloud_fixity_report.summary).to start_with "All files are preserved and their checksums verified."
      end
    end

    context "for a resource with a repairing cloud fixity event" do
      it "returns :repairing" do
        fs1 = create_file_set(cloud_fixity_status: Event::REPAIRING)
        FactoryBot.create(:local_fixity_success, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :repairing
        # Second check is cloud fixity
        cloud_fixity_report = report.checks.second
        expect(cloud_fixity_report.type).to eq "Cloud Fixity"
        expect(cloud_fixity_report.status).to eq :repairing
        expect(cloud_fixity_report.summary).to start_with "One or more files are in the process of being repaired."
      end
    end

    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    context "for a resource with a derivative that failed to process" do
      with_queue_adapter :inline
      it "returns :needs_attention with one unhealthy resource" do
        stub_ezid
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
        file_set = Wayfinder.for(resource).file_sets.first
        file_set.primary_file.error_message = "Broken!"
        file_set = ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)

        report = described_class.for(resource)
        file_set_report = described_class.for(file_set)

        expect(report.status).to eq :needs_attention
        expect(file_set_report.status).to eq :needs_attention

        derivative_report = report.checks.last
        list = derivative_report.unhealthy_resources
        expect(list.count).to eq 1
        expect(list[0][:title]).to eq resource.title.first
        expect(list[0][:url]).to include "#{resource.id}/file_manager"
      end
    end

    context "for a multivolume work with two derivatives that failed to process" do
      with_queue_adapter :inline
      it "returns :needs_attention with two unhealthy resources" do
        stub_ezid
        file1 = fixture_file_upload("files/example.tif", "image/tiff")
        file2 = fixture_file_upload("files/example.tif", "image/tiff")
        file3 = fixture_file_upload("files/example.tif", "image/tiff")
        file4 = fixture_file_upload("files/example.tif", "image/tiff")

        # Child resource with two broken files
        resource1 = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file1, file2])
        file_set = Wayfinder.for(resource1).file_sets.first
        file_set.primary_file.error_message = "Broken!"
        ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)
        file_set = Wayfinder.for(resource1).file_sets.last
        file_set.primary_file.error_message = "Broken!"
        ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)

        # Child resource with one broken file and one unbroken file
        resource2 = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file3, file4])
        file_set = Wayfinder.for(resource2).file_sets.first
        file_set.primary_file.error_message = "Broken!"
        ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)
        parent = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [resource1.id, resource2.id])

        report = described_class.for(parent)

        expect(report.status).to eq :needs_attention

        derivative_report = report.checks.last
        list = derivative_report.unhealthy_resources
        expect(list.count).to eq 2
        expect(list[0][:title]).to eq resource1.title.first
        expect(list[0][:url]).to include "#{resource1.id}/file_manager"
        expect(list[1][:title]).to eq resource2.title.first
        expect(list[1][:url]).to include "#{resource2.id}/file_manager"
      end
    end

    context "for a resource with a derivative that worked" do
      with_queue_adapter :inline
      it "returns :healthy with no unhealthy resources" do
        stub_ezid
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])

        report = described_class.for(resource)

        expect(report.status).to eq :healthy
        derivative_check = report.checks.find { |check| check.is_a? HealthReport::DerivativeCheck }
        list = derivative_check.unhealthy_resources
        expect(list.count).to eq 0
      end
    end

    context "for a resource with a derivative that hasn't processed yet" do
      with_queue_adapter :inline
      it "returns :in_progress with one unhealthy resource" do
        stub_ezid
        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, files: [file])
        file_set = Wayfinder.for(resource).file_sets.first
        file_set.processing_status = "in process"
        file_set = ChangeSetPersister.default.metadata_adapter.persister.save(resource: file_set)

        report = described_class.for(resource)
        file_set_report = described_class.for(file_set)

        expect(report.status).to eq :in_progress
        expect(file_set_report.status).to eq :in_progress

        derivative_check = report.checks.find { |check| check.is_a? HealthReport::DerivativeCheck }
        list = derivative_check.unhealthy_resources
        expect(list.count).to eq 1
      end
    end

    context "for a video" do
      with_queue_adapter :inline
      context "with captions" do
        it "returns healthy" do
          stub_ezid

          resource = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions, state: "complete")
          report = described_class.for(resource)
          expect(report.checks.length).to eq 4

          expect(report.status).to eq :healthy
          caption_check = report.checks.find { |check| check.is_a?(HealthReport::VideoCaptionCheck) }
          expect(caption_check.summary).to eq "Required Captions are present."
        end
        it "returns healthy for the file set" do
          stub_ezid

          resource = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions, state: "complete")
          report = described_class.for(Wayfinder.for(resource).file_sets.first)
          expect(report.checks.length).to eq 4

          expect(report.status).to eq :healthy
        end
      end
      context "without captions" do
        it "returns :needs_attention" do
          stub_ezid

          resource = FactoryBot.create_for_repository(:scanned_resource_with_video, state: "complete")
          report = described_class.for(resource)
          expect(report.checks.length).to eq 4

          expect(report.status).to eq :needs_attention
        end
        it "returns :healthy if the file set's marked as not requiring captions" do
          stub_ezid

          resource = FactoryBot.create_for_repository(:scanned_resource_with_silent_video, state: "complete")
          report = described_class.for(resource)
          expect(report.checks.length).to eq 4

          expect(report.status).to eq :healthy
        end
        it "returns :needs_attention for the file set" do
          stub_ezid

          resource = FactoryBot.create_for_repository(:scanned_resource_with_video, state: "complete")
          report = described_class.for(Wayfinder.for(resource).file_sets.first)
          expect(report.checks.length).to eq 4

          expect(report.status).to eq :needs_attention
        end
      end
    end
  end
end
