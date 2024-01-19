# frozen_string_literal: true
require "rails_helper"

RSpec.describe GeoDerivatives::Processors::BaseGeoProcessor do
  let(:processor) { TestProcessor.new }

  before do
    class TestProcessor
      include GeoDerivatives::Processors::BaseGeoProcessor
      include GeoDerivatives::Processors::Gdal
      def directives; end

      def source_path; end
    end

    allow(processor).to receive(:directives).and_return(directives)
    allow(processor).to receive(:source_path).and_return(file_name)
  end

  after { Object.send(:remove_const, :TestProcessor) }

  let(:directives) { { format: "png", size: "200x400" } }
  let(:output_file_jpg) { "output/geo.jpg" }
  let(:output_file_png) { "output/geo.png" }
  let(:output_file) { output_file_png }
  let(:file_name) { "files/geo.tif" }
  let(:options) { { output_size: "150 150" } }

  describe "#run_commands" do
    let(:method_queue) { [:translate, :warp, :compress] }

    context "when the processor raises an error" do
      before do
        allow(method_queue).to receive(:empty?).and_raise("error")
        allow(Dir).to receive(:exist?).and_return(true)
        allow(FileUtils).to receive(:rm_rf)
      end

      it "cleans the derivative intermediates" do
        expect { processor.class.run_commands(file_name, output_file, method_queue, options) }.to raise_error("error")
        expect(FileUtils).to have_received(:rm_rf).twice
      end
    end
  end

  context "when using GDAL processing" do
    before do
      class TestProcessor
        include Hydra::Derivatives::Processors::ShellBasedProcessor
        include GeoDerivatives::Processors::Gdal
        def directives; end

        def source_path; end
      end

      allow(processor).to receive(:directives).and_return(directives)
      allow(processor).to receive(:source_path).and_return(file_name)
      allow(processor.class).to receive(:execute)
    end

    let(:directives) { { format: "png", size: "200x400" } }
    let(:output_file) { "output/geo.png" }
    let(:file_name) { "files/geo.tif" }
    let(:options) { { output_size: "150 150", output_srid: "EPSG:4326" } }

    describe "#translate" do
      it "executes a gdal_translate command" do
        command = "gdal_translate -q -ot Byte -of GTiff -co TILED=YES -expand rgb -co COMPRESS=DEFLATE \"files/geo.tif\" output/geo.png"
        processor.class.translate(file_name, output_file, options)
        expect(processor.class).to have_received(:execute).with command
      end
    end

    describe "#warp" do
      it "executes a reproject command" do
        command = "gdalwarp -q -t_srs EPSG:4326 \"files/geo.tif\" output/geo.png -co TILED=YES -co COMPRESS=NONE"
        processor.class.warp(file_name, output_file, options)
        expect(processor.class).to have_received(:execute).with command
      end
    end

    describe "#compress" do
      it "returns a gdal_translate command with a compress option" do
        command = "gdal_translate -q -ot Byte -a_srs EPSG:4326 \"files/geo.tif\" output/geo.png -co COMPRESS=JPEG -co JPEG_QUALITY=90"
        processor.class.compress(file_name, output_file, options)
        expect(processor.class).to have_received(:execute).with command
      end
    end

    describe "#rasterize" do
      it "executes a rasterize command" do
        command = "gdal_rasterize -q -burn 0 -init 255 -ot Byte -ts 150 150 -of GTiff \"files/geo.tif\" output/geo.png"
        processor.class.rasterize(file_name, output_file, options)
        expect(processor.class).to have_received(:execute).with command
      end
    end
  end
end
