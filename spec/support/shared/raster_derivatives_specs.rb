# frozen_string_literal: true
RSpec.shared_examples "a set of raster derivatives" do
  it "creates display raster and thumbnail derivatives" do
    expect do
      GeoDerivatives::Runners::RasterDerivatives.create(input_file_path, outputs: outputs)
    end.to change { File.exist?(display_raster_uri.path) && File.exist?(thumbnail_uri.path) }
      .from(false).to(true)
  end
end
