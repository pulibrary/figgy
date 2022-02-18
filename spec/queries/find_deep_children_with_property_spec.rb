# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindDeepChildrenWithProperty do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_deep_children_with_property" do
    it "finds all children through a hierarchy with a given property" do
      fs1 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      fs2 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      fs3 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      ok_fs = FactoryBot.create_for_repository(:file_set, processing_status: "processed")
      # Create unrelated FS
      FactoryBot.create_for_repository(:file_set)
      volume1 = FactoryBot.create_for_repository(:scanned_resource, member_ids: fs1.id)
      volume2 = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs2.id, ok_fs.id])
      mvw = FactoryBot.create_for_repository(:scanned_resource, member_ids: [volume1.id, volume2.id, fs3.id])

      output = query.find_deep_children_with_property(resource: mvw, model: FileSet, property: :processing_status, value: "in process")

      expect(output.map(&:id)).to contain_exactly fs1.id, fs2.id, fs3.id
    end
    it "provides a count if given one" do
      fs1 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      fs2 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      fs3 = FactoryBot.create_for_repository(:file_set, processing_status: "in process")
      ok_fs = FactoryBot.create_for_repository(:file_set, processing_status: "processed")
      # Create unrelated FS
      FactoryBot.create_for_repository(:file_set)
      volume1 = FactoryBot.create_for_repository(:scanned_resource, member_ids: fs1.id)
      volume2 = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs2.id, ok_fs.id])
      mvw = FactoryBot.create_for_repository(:scanned_resource, member_ids: [volume1.id, volume2.id, fs3.id])

      output = query.find_deep_children_with_property(resource: mvw, model: FileSet, property: :processing_status, value: "in process", count: true)

      expect(output).to eq 3
    end
  end
end
