# frozen_string_literal: true
require "rails_helper"
require "shrine/storage/s3"

RSpec.describe MosaicCacheService do
  describe "#invalidate" do
    let(:aws_client) { instance_double(Aws::CloudFront::Client) }
    let(:distributions) { double("Seahorse::Client::Response") }
    let(:distribution_list) { instance_double(Aws::CloudFront::Types::DistributionList) }
    let(:item) { instance_double(Aws::CloudFront::Types::DistributionSummary) }
    let(:aliases) { instance_double(Aws::CloudFront::Types::Aliases) }
    let(:alias_items) { [tile_server_url] }
    let(:tile_server_url) { Figgy.config["tileserver"][:url] }
    let(:id) { "E3ZZ2ZSZZZ0Z8" }
    let(:params) do
      {
        distribution_id: id,
        invalidation_batch:
          {
            caller_reference: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd",
            paths:
              {
                items: [path],
                quantity: 1
              }
          }
      }
    end

    before do
      allow(Aws::CloudFront::Client).to receive(:new).and_return(aws_client)
      allow(aws_client).to receive(:list_distributions).and_return(distributions)
      allow(aws_client).to receive(:create_invalidation)
      allow(distributions).to receive(:distribution_list).and_return(distribution_list)
      allow(distribution_list).to receive(:items).and_return([item])
      allow(item).to receive(:aliases).and_return(aliases)
      allow(aliases).to receive(:items).and_return(alias_items)
      allow(item).to receive(:id).and_return(id)
    end

    context "when running the service with the mosaic_only set to true" do
      let(:path) { "/resources/331d70a5-4bd9-4a65-80e4-763c8f6b34fd" }

      it "makes a call to the Cloudfront API to invalidate only the mosaic path" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        described_class.new(resource: raster_set).invalidate
        expect(aws_client).to have_received(:create_invalidation).with(params)
      end
    end

    context "when running the service with mosaic_only set to false" do
      let(:path) { "*331d70a5-4bd9-4a65-80e4-763c8f6b34fd*" }

      it "makes a call to the Cloudfront API to invalidate all paths that match the resource id" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, id: "331d70a5-4bd9-4a65-80e4-763c8f6b34fd")
        described_class.new(resource: raster_set, mosaic_only: false).invalidate
        expect(aws_client).to have_received(:create_invalidation).with(params)
      end
    end
  end
end
