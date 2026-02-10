require "rails_helper"
require "support/preserved_objects"

RSpec.describe PreservationCheckFailure, type: :model do
  describe "#details_hash" do
    context "with a preserved resource" do
      with_queue_adapter :inline

      it "returns a hash that we can use to generate a CSV for investigating failures" do
        stub_ezid
        preserved_resource = create_preserved_resource
        file_set = Wayfinder.for(preserved_resource).members.first

        audit = FactoryBot.create(:preservation_audit)
        failure = described_class.new(resource_id: file_set.id, preservation_audit: audit)
        expect(failure.details_hash).to eq({
          id: file_set.id,
          resource_class: FileSet,
          created_at: file_set.created_at,
          updated_at: file_set.updated_at,
          mime_type: ["image/tiff"],
          preservation_object?: true,
          metadata_preserved?: true,
          m_preservation_file_exists?: true,
          m_preservation_ids_match?: true,
          m_recorded_versions_match?: true,
          m_preserved_checksums_match?: true,
          binaries_preserved?: true,
          preservation_ids_match?: [true],
          recorded_checksums_match?: [true]
        })
      end
    end

    context "when the resource no longer exists" do
      it "returns a hash full of nils" do
        audit = FactoryBot.create(:preservation_audit)
        failure = described_class.new(resource_id: "1234", preservation_audit: audit)
        expect(failure.details_hash).to eq({
          id: "1234",
          resource_class: nil,
          created_at: nil,
          updated_at: nil,
          mime_type: nil,
          preservation_object?: false,
          metadata_preserved?: false,
          m_preservation_file_exists?: nil,
          m_preservation_ids_match?: nil,
          m_recorded_versions_match?: nil,
          m_preserved_checksums_match?: nil,
          binaries_preserved?: false,
          preservation_ids_match?: nil,
          recorded_checksums_match?: nil
        })
      end
    end

    context "when the resource has no preservation object" do
      it "doesn't error" do
        audit = FactoryBot.create(:preservation_audit)
        resource = FactoryBot.create_for_repository(:original_image_file_set)
        failure = described_class.new(resource_id: resource.id, preservation_audit: audit)
        expect(failure.details_hash).to eq({
          id: resource.id,
          resource_class: FileSet,
          created_at: resource.created_at,
          updated_at: resource.updated_at,
          mime_type: ["image/tiff"],
          preservation_object?: false,
          metadata_preserved?: false,
          m_preservation_file_exists?: nil,
          m_preservation_ids_match?: nil,
          m_recorded_versions_match?: nil,
          m_preserved_checksums_match?: nil,
          binaries_preserved?: false,
          preservation_ids_match?: nil,
          recorded_checksums_match?: nil
        })
      end
    end
  end
end
