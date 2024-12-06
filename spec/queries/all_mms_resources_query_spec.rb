# frozen_string_literal: true
require "rails_helper"

describe AllMmsResourcesQuery do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  describe "#all_mms_resources" do
    it "finds all resources with an mms id" do
      stub_catalog(bib_id: "9985434293506421")
      stub_findingaid(pulfa_id: "AC044_c0003")
      mms_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "9985434293506421")
      _component_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "AC044_c0003")
      expect(query.all_mms_resources.map(&:id).to_a).to eq [mms_resource.id]
    end

    it "can filter by created_at" do
      id1 = "9985434293506421"
      id2 = "9946093213506421"
      stub_catalog(bib_id: id1)
      stub_catalog(bib_id: id2)
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: id1)
      Timecop.travel(2021, 6, 30) do
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: id2)
      end

      output = query.all_mms_resources(created_at: DateTime.new(2021, 3, 30)..DateTime.new(2021, 8, 30))
      expect(output.flat_map(&:source_metadata_identifier)).to eq [id2]
    end
  end

  describe "#mms_title_resources" do
    it "finds all resources with a title that looks like an mms id" do
      mms_resource = FactoryBot.create_for_repository(:scanned_resource, title: "9985434293506421")
      FactoryBot.create_for_repository(:file_set, title: "9985434293506421.pdf")
      FactoryBot.create_for_repository(:scanned_resource, title: "Totally normal resource with regular title")
      result = query.mms_title_resources
      expect(result.map(&:id).to_a).to eq [mms_resource.id]
    end

    it "can filter by created_at" do
      title1 = "9985434293506421"
      title2 = "9946093213506421"
      FactoryBot.create_for_repository(:scanned_resource, title: title1)
      Timecop.travel(2021, 6, 30) do
        FactoryBot.create_for_repository(:scanned_resource, title: title2)
      end

      output = query.mms_title_resources(created_at: DateTime.new(2021, 3, 30)..DateTime.new(2021, 8, 30))
      expect(output.flat_map(&:title)).to eq [title2]
    end
  end
end
