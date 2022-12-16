# frozen_string_literal: true
require "rails_helper"

describe GeoDiscovery::DocumentBuilder::IIIFBuilder do
  with_queue_adapter :inline

  let(:builder) { described_class.new(decorator) }
  let(:scanned_map) { FactoryBot.create_for_repository(:scanned_map, visibility: visibility) }
  let(:decorator) { query_service.find_by(id: scanned_map.id).decorate }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { ScannedMapChangeSet.new(scanned_map, files: [file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:document) { GeoDiscovery::GeoblacklightDocument.new }

  before do
    output = change_set_persister.save(change_set: change_set)
    file_set_id = output.member_ids[0]
    file_set = query_service.find_by(id: file_set_id)
    file_set.primary_file.mime_type = "image/tiff"
    metadata_adapter.persister.save(resource: file_set)
  end

  describe "#iiif_path" do
    context "when an ObjectNotFoundError exception is raised" do
      let(:helper) { instance_double(ManifestBuilder::ManifestHelper) }

      before do
        allow(builder).to receive(:helper).and_return(helper)
        allow(helper).to receive(:manifest_image_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(helper).to receive(:manifest_url)
      end

      it "returns a nil path" do
        builder.build(document)
        expect(document.iiif).to be_nil
      end
    end
  end
end
