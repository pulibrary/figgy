# frozen_string_literal: true
require "rails_helper"

describe AllIdsQuery do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe "#all_ids" do
    context "when not given any arguments" do
      it "finds all ids" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        expect(query.all_ids.to_a).to eq [resource.id]
      end
    end

    context "when given except_models argument" do
      it "finds everything that isn't one of those models" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        FactoryBot.create_for_repository(:raster_resource)
        FactoryBot.create_for_repository(:file_set)

        expect(query.all_ids(except_models: [RasterResource, FileSet]).to_a).to eq [resource.id]
      end
    end
  end
end
