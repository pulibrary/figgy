# frozen_string_literal: true
require "rails_helper"
require "fileutils"

RSpec.describe GeoDerivatives::Runners::VectorDerivatives do
  describe "#create" do
    let(:outputs) do
      [
        {
          input_format: input_mime_type,
          label: :display_vector,
          id: "file_set_id",
          format: "zip",
          url: display_vector_uri
        },
        {
          input_format: input_mime_type,
          label: :cloud_vector,
          id: "file_set_id",
          format: "pmtiles",
          url: cloud_vector_uri
        },
        {
          input_format: input_mime_type,
          label: :thumbnail,
          id: "file_set_id",
          format: "png",
          size: "200x150",
          url: thumbnail_uri
        }
      ]
    end

    before do
      described_class.source_file_service = LocalFileService
      described_class.output_file_service = OutputFileService
    end

    after do
      # Cleanup generated derivatives, unless KEEP env variable is set
      unless ENV["KEEP"]
        FileUtils.rm(cloud_vector_uri.path)
        FileUtils.rm(display_vector_uri.path)
        FileUtils.rm(thumbnail_uri.path)
      end
    end

    context "with a zipped shapefile" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/shapefile.zip")) }
      let(:input_mime_type) { 'application/zip; ogr-format="ESRI Shapefile"' }
      let(:cloud_vector_uri) { test_derivative_url("shapefile_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("shapefile_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("shapefile_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a zipped shapefile with an unsafe filename" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/shapefile_&_unsafe.zip")) }
      let(:input_mime_type) { 'application/zip; ogr-format="ESRI Shapefile"' }
      let(:cloud_vector_uri) { test_derivative_url("shapefile_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("shapefile_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("shapefile_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a zipped shapefile that has a single feature" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/taiwan.zip")) }
      let(:input_mime_type) { 'application/zip; ogr-format="ESRI Shapefile"' }
      let(:cloud_vector_uri) { test_derivative_url("shapefile_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("shapefile_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("shapefile_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a geojson file" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/geo.json")) }
      let(:input_mime_type) { "application/vnd.geo+json" }
      let(:cloud_vector_uri) { test_derivative_url("geojson_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("geojson_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("geojson_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a geojson file with an unsafe filename" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/geo_&_unsafe.json")) }
      let(:input_mime_type) { "application/vnd.geo+json" }
      let(:cloud_vector_uri) { test_derivative_url("geo_&_unsafe_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("geo_&_unsafe_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("geo_&_unsafe_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a KML file" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/example.kml")) }
      let(:input_mime_type) { "application/vnd.google-earth.kml+xml" }
      let(:cloud_vector_uri) { test_derivative_url("kml_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("kml_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("kml_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end

    context "with a geopackage" do
      let(:input_file_path) { Pathname.new(file_fixture("files/vector/geopackage.gpkg")) }
      let(:input_mime_type) { "application/geopackage+sqlite3" }
      let(:cloud_vector_uri) { test_derivative_url("geopackage_cloud_vector", "pmtiles") }
      let(:display_vector_uri) { test_derivative_url("geopackage_display_vector", "zip") }
      let(:thumbnail_uri) { test_derivative_url("geopackage_thumbnail", "png") }

      it_behaves_like "a set of vector derivatives"
    end
  end
end
