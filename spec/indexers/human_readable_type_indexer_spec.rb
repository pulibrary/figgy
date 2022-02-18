# frozen_string_literal: true

require "rails_helper"

RSpec.describe HumanReadableTypeIndexer do
  describe ".to_solr" do
    let(:scanned_resource) { FactoryBot.create(:pending_scanned_resource) }
    it "indexes the human readable type name for a scanned resource" do
      output = described_class.new(resource: scanned_resource).to_solr

      expect(output[:human_readable_type_ssim]).to eq "Scanned Resource"
    end

    context "when a raster resource has child raster members" do
      it "indexes it as a Raster Set" do
        member_raster = FactoryBot.create_for_repository(:raster_resource)
        parent_raster = FactoryBot.create_for_repository(:raster_resource, member_ids: [member_raster.id])

        output = described_class.new(resource: parent_raster).to_solr

        expect(output[:human_readable_type_ssim]).to eq "Raster Set"
      end
    end

    context "when a scanned resource has multiple volumes" do
      let(:child_volume) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [child_volume.id]) }
      it "indexes the scanned resource as a multi-volume work" do
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:human_readable_type_ssim]).to eq "Multi Volume Work"
      end
    end

    context "when a scanned resource is a recording" do
      let(:scanned_resource) { FactoryBot.create(:recording) }
      it "indexes human readeable type name for a recording" do
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:human_readable_type_ssim]).to eq "Recording"
      end
    end

    context "when a scanned resource is a simple resource" do
      let(:scanned_resource) { FactoryBot.create(:simple_resource) }
      it "indexes human readeable type name for a simple resource" do
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:human_readable_type_ssim]).to eq "Simple Resource"
      end
    end

    context "when a scanned map has scanned map members" do
      let(:child_member) { FactoryBot.create_for_repository(:scanned_map) }
      let(:scanned_map) { FactoryBot.create_for_repository(:scanned_map, member_ids: [child_member.id]) }
      it "indexes the scanned map as a map set" do
        output = described_class.new(resource: scanned_map).to_solr

        expect(output[:human_readable_type_ssim]).to eq "Map Set"
      end
    end

    context "when indexing an ArchivalMediaCollection" do
      let(:resource) do
        FactoryBot.create_for_repository(:collection, change_set: "archival_media_collection")
      end
      let(:output) do
        described_class.new(resource: resource).to_solr
      end

      it "indexes as both a Collection and ArchivalMediaCollection" do
        expect(output).to include :human_readable_type_ssim
        expect(output[:human_readable_type_ssim]).to eq(["Collection", "Archival Media Collection"])
      end
    end

    context "when indexing a resource with an invalid ChangeSet" do
      let(:resource) do
        FactoryBot.create_for_repository(:collection, change_set: "invalid")
      end
      let(:output) do
        described_class.new(resource: resource).to_solr
      end

      before do
        allow(Valkyrie.logger).to receive(:warn)
      end

      it "indexes as just the human readable type name" do
        expect(output).to include :human_readable_type_ssim
        expect(output[:human_readable_type_ssim]).to eq("Collection")
        expect(Valkyrie.logger).to have_received(:warn).with("invalid is not a valid resource type.")
      end
    end
  end
end
