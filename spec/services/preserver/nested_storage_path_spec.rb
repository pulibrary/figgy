# frozen_string_literal: true

require "rails_helper"

RSpec.describe Preserver::NestedStoragePath do
  describe "#generate" do
    context "when there's no parent" do
      it "nests the file inside a directory named after the id" do
        resource = instance_double(ScannedResource)
        allow(resource).to receive(:persisted?).and_return(true)
        allow(resource).to receive(:id).and_return(Valkyrie::ID.new("id"))

        storage_path = described_class.new(base_path: "")
        path = storage_path.generate(resource: resource, file: nil, original_filename: "bla.tif")

        expect(path).to eq Pathname.new("id/bla.tif")
      end
    end
    context "when there's a parent" do
      it "nests the file inside a parent's data directory" do
        resource = instance_double(ScannedResource, persisted?: true, id: Valkyrie::ID.new("id"))
        parent = instance_double(ScannedResource, persisted?: true, id: Valkyrie::ID.new("parent"))
        wayfinder = instance_double(ScannedResourceWayfinder, parent: parent)
        allow(Wayfinder).to receive(:for).and_call_original
        allow(Wayfinder).to receive(:for).with(resource).and_return(wayfinder)

        storage_path = described_class.new(base_path: "")
        path = storage_path.generate(resource: resource, file: nil, original_filename: "bla.tif")

        expect(path).to eq Pathname.new("parent/data/id/bla.tif")
      end
    end
  end
end
