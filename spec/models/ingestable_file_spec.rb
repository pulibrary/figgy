# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestableFile do
  it "delegates IO methods to a file" do
    file = described_class.new(file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"))

    expect(file).to respond_to(:read)
  end
end
