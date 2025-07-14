# frozen_string_literal: true
require "rails_helper"

describe Dspace::Resource do
  subject(:resource) { described_class.new(resource_data, client) }

  let(:handle) { "88435/dsp016q182k16g" }
  let(:token) { "bla" }
  let(:client) { Dspace::Client.new(handle, token) }

  let(:item_fixture_path) { Rails.root.join("spec", "fixtures", "dspace", "1672.json") }
  let(:item_fixture) { File.read(item_fixture_path) }
  let(:resource_data) { JSON.parse(item_fixture) }

  describe "#dir" do
    it "returns the ending for the ARK" do
      expect(resource.dir).to eq "dsp012801pg38m"
    end
  end
end
