# frozen_string_literal: true
require "rails_helper"

RSpec.describe MemberOfIndexer do
  describe ".to_solr" do
    context "for scanned resources" do
      it "indexes parent resource ids" do
        child = FactoryBot.create_for_repository(:scanned_resource)
        parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)
        output = described_class.new(resource: child).to_solr

        expect(output["member_of_ssim"]).to eq ["id-#{parent.id}"]
      end
    end

    context "for raster resources" do
      it "indexes parent resource ids" do
        child = FactoryBot.create_for_repository(:raster_resource)
        parent = FactoryBot.create_for_repository(:raster_resource, member_ids: child.id)
        output = described_class.new(resource: child).to_solr

        expect(output["member_of_ssim"]).to eq ["id-#{parent.id}"]
      end
    end
  end
end
