# frozen_string_literal: true
require "rails_helper"
require "fileutils"

RSpec.describe GeoDerivatives::Runners::RasterDerivatives do
  describe "#create" do
    let(:outputs) do
      [
        {
          input_format: input_mime_type,
          label: :display_raster,
          id: "file_set_id",
          format: "tif",
          url: display_raster_uri
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
        FileUtils.rm(display_raster_uri.path)
        FileUtils.rm(thumbnail_uri.path)
      end
    end

    context "with a geotiff with a color map" do
      let(:input_file_path) { Pathname.new(file_fixture("files/raster/geotiff-color-map.tif")) }
      let(:input_mime_type) { "image/tiff; gdal-format=GTiff" }
      let(:display_raster_uri) { test_derivative_url("geotiff_color_map_display_raster", "tif") }
      let(:thumbnail_uri) { test_derivative_url("geotiff_color_map_thumbnail", "png") }

      it_behaves_like "a set of raster derivatives"
    end

    context "with a geotiff with no color map" do
      let(:input_file_path) { Pathname.new(file_fixture("files/raster/geotiff-no-color-map.tif")) }
      let(:input_mime_type) { "image/tiff; gdal-format=GTiff" }
      let(:display_raster_uri) { test_derivative_url("geotiff_no_color_map_display_raster", "tif") }
      let(:thumbnail_uri) { test_derivative_url("geotiff_no_color_map_thumbnail", "png") }

      it_behaves_like "a set of raster derivatives"
    end

    context "with a geotiff with an unsafe filename" do
      let(:input_file_path) { Pathname.new(file_fixture("files/raster/geotiff_&_unsafe.tif")) }
      let(:input_mime_type) { "image/tiff; gdal-format=GTiff" }
      let(:display_raster_uri) { test_derivative_url("geotiff_&_unsafe_display_raster", "tif") }
      let(:thumbnail_uri) { test_derivative_url("geotiff_&_unsafe_thumbnail", "png") }

      it_behaves_like "a set of raster derivatives"
    end

    context "with an ArcGrid file" do
      let(:input_file_path) { Pathname.new(file_fixture("files/raster/arcgrid.zip")) }
      let(:input_mime_type) { "application/octet-stream; gdal-format=AIG" }
      let(:display_raster_uri) { test_derivative_url("arcgrid_display_raster", "tif") }
      let(:thumbnail_uri) { test_derivative_url("arcgrid_thumbnail", "png") }

      it_behaves_like "a set of raster derivatives"
    end

    context "with a digital elevation model file" do
      let(:input_file_path) { Pathname.new(file_fixture("files/raster/example.dem")) }
      let(:input_mime_type) { "text/plain; gdal-format=USGSDEM" }
      let(:display_raster_uri) { test_derivative_url("dem_display_raster", "tif") }
      let(:thumbnail_uri) { test_derivative_url("dem_thumbnail", "png") }

      it_behaves_like "a set of raster derivatives"
    end
  end
end
