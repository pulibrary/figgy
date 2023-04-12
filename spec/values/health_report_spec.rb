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
    context "for a resource with a failed local fixity event" do
      it "returns :needs_attention" do
        fs1 = FactoryBot.create_for_repository(:original_file_file_set)
        FactoryBot.create(:local_fixity_failure, resource_id: fs1.id)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :needs_attention
      end
    end
    context "for a resource with a failed cloud fixity event" do
      it "returns :needs_attention" do
        fs1 = create_file_set(cloud_fixity_success: false)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs1.id])

        report = described_class.for(resource)

        expect(report.status).to eq :needs_attention
      end

      # rubocop:disable Metrics/MethodLength
      def create_file_set(cloud_fixity_success: true)
        file_set = FactoryBot.create_for_repository(:file_set)
        metadata_node = FileMetadata.new(id: SecureRandom.uuid)
        preservation_object = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, metadata_node: metadata_node)
        if cloud_fixity_success
          FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "SUCCESS",
                                                   resource_id: preservation_object.id, child_id: metadata_node.id,
                                                   child_property: :metadata_node, current: true)
        else
          FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "FAILURE",
                                                   resource_id: preservation_object.id, child_id: metadata_node.id,
                                                   child_property: :metadata_node, current: true)
        end
        file_set
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
