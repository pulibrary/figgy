# frozen_string_literal: true

require "rails_helper"

describe GeoDiscovery::DocumentBuilder::Wxs do
  with_queue_adapter :inline
  subject(:wxs_builder) { described_class.new(decorator) }

  let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility) }
  let(:decorator) { query_service.find_by(id: geo_work.id).decorate }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", 'application/zip; ogr-format="ESRI Shapefile"') }
  let(:tika_output) { tika_shapefile_output }

  before do
    output = change_set_persister.save(change_set: change_set)
    file_set_id = output.member_ids[0]
    file_set = query_service.find_by(id: file_set_id)
    file_set.original_file.mime_type = 'application/zip; ogr-format="ESRI Shapefile"'
    metadata_adapter.persister.save(resource: file_set)
  end

  describe "#identifier" do
    context "public document" do
      it "returns a public identifier" do
        file_set_id = geo_work.member_ids[0]
        expect(wxs_builder.identifier).to eq "public-figgy:p-#{file_set_id}"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns the fileset id" do
        file_set_id = geo_work.member_ids[0]
        expect(wxs_builder.identifier).to eq file_set_id.to_s
      end
    end

    context "when the layer_name property is set on the resource" do
      let(:layer_name) { "layer" }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, layer_name: layer_name) }

      it "returns the overridden identifier" do
        expect(wxs_builder.identifier).to eq layer_name
      end
    end
  end

  describe "#wms_path" do
    context "public document" do
      it "returns a public wms path" do
        expect(wxs_builder.wms_path).to eq "http://localhost:8080/geoserver/public-figgy/wms"
      end
    end

    context "restricted document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns a restricted value" do
        expect(wxs_builder.wms_path).to eq "http://localhost:8080/geoserver/restricted-figgy/wms"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.wms_path).to be_nil
      end
    end

    context "when the wms_url property is set on the resource" do
      let(:wms_url) { "https://geoserver.princeton.edu/geoserver/mosaics/wms" }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wms_url: wms_url) }

      it "returns a the overriden wms value" do
        expect(wxs_builder.wms_path).to eq wms_url
      end
    end
  end

  describe "#wfs_path" do
    context "public document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns a valid wfs path" do
        expect(wxs_builder.wfs_path).to eq "http://localhost:8080/geoserver/public-figgy/wfs"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.wfs_path).to be_nil
      end
    end

    context "when the wfs_url property is set on the resource" do
      let(:wfs_url) { "https://geoserver.princeton.edu/geoserver/mosaics/wfs" }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wfs_url: wfs_url) }

      it "returns a the overriden wfs value" do
        expect(wxs_builder.wfs_path).to eq wfs_url
      end
    end
  end
end
