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

    it "sorts by date created" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      resource2 = Timecop.travel(Time.current - 1.day) do
        FactoryBot.create_for_repository(:scanned_resource)
      end

      expect(query.all_ids.to_a).to eq [resource2.id, resource.id].map(&:to_s)
    end

    context "when given limit and offset" do
      it "returns only those ids" do
        _r0 = FactoryBot.create_for_repository(:scanned_resource)
        _r1 = FactoryBot.create_for_repository(:scanned_resource)
        r2 = FactoryBot.create_for_repository(:scanned_resource)
        r3 = FactoryBot.create_for_repository(:scanned_resource)
        _r4 = FactoryBot.create_for_repository(:scanned_resource)

        # when batch size is 2 and index is 0: [2, 0]
        # when batch size is 2 and index is 1: [2, 2]
        expect(query.all_ids(limit_offset_tuple: [2, 2]).to_a).to eq [r2, r3].map(&:id).map(&:to_s)
      end
    end
  end
end
