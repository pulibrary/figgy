# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReprocessMetsJob do
  context "when given a collection with objects that have METS files" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }
    it "regenerates properties into those objects" do
      stub_ezid(shoulder: "88435", blade: "ww72bb49w", location: "http://findingaids.princeton.edu/collections/AC111")
      file = IngestableFile.new(
        file_path: mets_file,
        mime_type: "application/xml; schema=mets",
        original_filename: File.basename(mets_file),
        copyable: false
      )
      image_file = IngestableFile.new(
        file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"),
        mime_type: "image/tiff",
        original_filename: "example.tif",
        copyable: false
      )
      collection = FactoryBot.create_for_repository(:collection)
      resource = FactoryBot.create_for_repository(:simple_resource, member_of_collection_ids: collection.id, files: [file, image_file])
      described_class.perform_now(collection_id: collection.id.to_s)

      reloaded_resource = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource.id)
      expect(reloaded_resource.title).to eq ["Aaron Burr Hall"]
    end
  end
end
