# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Preserver::BlindImporter do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:query_service) { ScannedResourcesController.change_set_persister.query_service }
  let(:persister) { ScannedResourcesController.change_set_persister.metadata_adapter.persister }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:importer) { described_class.new }
  with_queue_adapter :inline
  before do
    stub_ezid(shoulder: shoulder, blade: blade)
  end
  describe ".import" do
    it "imports a preserved resource given an ID" do
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, preservation_policy: "cloud", files: [file])
      children = query_service.find_members(resource: resource)

      # Delete them without running callbacks which clean up from disk.
      persister.delete(resource: resource)
      children.each do |child|
        persister.delete(resource: child)
      end

      output = described_class.import(id: resource.id)
      expect(output.id).to eq resource.id
      expect(output.member_ids.length).to eq 1
      file_sets = query_service.find_members(resource: output)

      expect(file_sets.length).to eq 1
      expect(file_sets[0].id).to eq children.first.id
    end
  end
end
