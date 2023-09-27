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
      it "only checks local fixity" do
        resource = FactoryBot.create_for_repository(:pending_scanned_resource)

        report = described_class.for(resource)

        expect(report.checks.length).to eq 1
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
        expect(report.checks.length).to eq 2
      end
      it "can report if it's repairing" do
        project = FactoryBot.create_for_repository(:ephemera_project)
        create_preservation_object(event_status: Event::REPAIRING, resource_id: project.id, event_type: :cloud_fixity)

        report = described_class.for(project)
        expect(report.status).to eq :repairing
        expect(report.checks.length).to eq 2
      end
    end
    it "can report if it's in progress (no preservation object)" do
      project = FactoryBot.create_for_repository(:ephemera_project)

      report = described_class.for(project)

      expect(report.status).to eq :in_progress
      expect(report.checks.length).to eq 2
    end
    it "can report if it needs attention" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      create_preservation_object(event_status: Event::FAILURE, resource_id: project.id, event_type: :cloud_fixity)

      report = described_class.for(project)
      expect(report.status).to eq :needs_attention
      expect(report.checks.length).to eq 2
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
      end
    end
    context "for a FileSet with a failed local fixity event" do
      it "returns :needs_attention" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        FactoryBot.create(:local_fixity_failure, resource_id: fs1.id)
        FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [fs1.id])

        report = described_class.for(fs1)

        expect(report.status).to eq :needs_attention
        # First check is local fixity
        local_fixity_report = report.checks.first
        expect(local_fixity_report.type).to eq "Local Fixity"
        expect(local_fixity_report.status).to eq :needs_attention
        expect(local_fixity_report.summary).to start_with "This resource failed Local Fixity Checks."
      end
    end

    context "for a resource with a failed cloud fixity event" do
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
    # rubocop:disable Metrics/MethodLength
    def create_file_set(cloud_fixity_status:)
      file_set = FactoryBot.create_for_repository(:file_set)
      create_preservation_object(resource_id: file_set.id, event_status: cloud_fixity_status, event_type: :cloud_fixity)
      file_set
    end

    def create_preservation_object(event_status:, resource_id:, event_type:)
      metadata_node = FileMetadata.new(id: SecureRandom.uuid)
      preservation_object = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: resource_id, metadata_node: metadata_node)
      FactoryBot.create_for_repository(
        :event,
        type: event_type,
        status: event_status,
        resource_id: preservation_object.id,
        child_id: metadata_node.id,
        child_property: :metadata_node,
        current: true
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
