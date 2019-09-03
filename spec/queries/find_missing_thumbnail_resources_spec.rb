# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindMissingThumbnailResources do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:query_service) { metadata_adapter.query_service }
  let(:resource) do
    sr = FactoryBot.create_for_repository(:scanned_resource)
    change_set = ScannedResourceChangeSet.new(sr)
    change_set.thumbnail_id = nil
    change_set_persister.save(change_set: change_set)
  end
  let(:file) { fixture_file_upload("files/color-landscape.tif", "image/tiff") }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    stub_bibdata(bib_id: "123456")
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")
  end

  describe "#find_missing_thumbnail_resources" do
    let(:connection) { Blacklight.default_index.connection }
    before do
      resource
    end
    it "only finds resources missing thumbnails" do
      output = query.find_missing_thumbnail_resources(model: ScannedResource)
      ids = output.map(&:id)
      expect(ids).to include resource.id
      expect(ids).not_to include resource2.id
    end
  end
end
