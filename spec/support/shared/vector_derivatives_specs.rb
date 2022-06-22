# frozen_string_literal: true
RSpec.shared_examples "a set of vector derivatives" do
  it "creates display vector and thumbnail derivatives" do
    expect do
      GeoDerivatives::Runners::VectorDerivatives.create(input_file_path, outputs: outputs)
    end.to change { File.exist?(display_vector_uri.path) && File.exist?(thumbnail_uri.path) }
      .from(false).to(true)
  end
end
