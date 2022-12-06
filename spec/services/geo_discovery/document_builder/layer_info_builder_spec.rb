# frozen_string_literal: true
require "rails_helper"

describe GeoDiscovery::DocumentBuilder::LayerInfoBuilder do
  with_queue_adapter :inline

  let(:builder) { described_class.new(decorator) }
  let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility) }
  let(:decorator) { query_service.find_by(id: geo_work.id).decorate }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", 'application/zip; ogr-format="ESRI Shapefile"') }
  let(:tika_output) { tika_shapefile_output }

  let(:document) { GeoDiscovery::GeoblacklightDocument.new }
  let(:geometry) { "None" }

  before do
    allow(GeoserverPublishJob).to receive(:perform_later)
    output = change_set_persister.save(change_set: change_set)
    file_set_id = output.member_ids[0]
    file_set = query_service.find_by(id: file_set_id)
    file_set.primary_file.mime_type = 'application/zip; ogr-format="ESRI Shapefile"'
    file_set.primary_file.geometry = geometry
    metadata_adapter.persister.save(resource: file_set)
  end

  describe "#vector_geom_type" do
    context "with a geometry value of None" do
      it "returns a value of Mixed" do
        builder.build(document)
        expect(document.geom_types).to eq(["Mixed"])
      end
    end

    context "with a geometry value of Multi Point" do
      let(:geometry) { "Multi Point" }

      it "returns a value of Point" do
        builder.build(document)
        expect(document.geom_types).to eq(["Point"])
      end
    end

    context "with a geometry value of 3D Line String" do
      let(:geometry) { "3D Line String" }

      it "returns a value of Line" do
        builder.build(document)
        expect(document.geom_types).to eq(["Line"])
      end
    end

    context "with a geometry value of Measured Line String" do
      let(:geometry) { "Measured Line String" }

      it "returns a value of Line" do
        builder.build(document)
        expect(document.geom_types).to eq(["Line"])
      end
    end
  end
end
