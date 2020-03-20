# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder::CantaloupeHelper do
  with_queue_adapter :inline
  let(:cantaloupe_helper) { described_class.new }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { query_service.find_members(resource: scanned_resource).to_a.first }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:derivative_file) { file_set.derivative_file }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

  describe "#base_url", run_real_derivatives: true do
    context "with generated derivatives" do
      it "generates a base URL for a pyramidal if it's present" do
        path = Valkyrie::StorageAdapter.find_by(id: file_set.pyramidal_derivative.file_identifiers[0]).io.path
        path = path.gsub(Figgy.config["pyramidal_derivative_path"], "").gsub(/^\//, "").gsub(".tif", "")
        expect(cantaloupe_helper.base_url(file_set)).to eq "http://localhost:8182/iiif/2/#{path.gsub('/', '%2F')}"
      end
      it "generates a base URL for a JPEG2000 derivative" do
        path = Valkyrie::StorageAdapter.find_by(id: derivative_file.file_identifiers[0]).io.path
        path = path.gsub(Figgy.config["derivative_path"], "").gsub(/^\//, "")
        allow(file_set).to receive(:pyramidal_derivative).and_return(nil)
        expect(cantaloupe_helper.base_url(file_set)).to eq "http://localhost:8182/iiif/2/#{path.gsub('/', '%2F')}"
      end
    end
    context "when something goes wrong finding the path" do
      it "returns nil" do
        allow(file_set).to receive(:pyramidal_derivative).and_return(nil)
        allow(derivative_file).to receive(:file_identifiers).and_raise(StandardError)
        expect(cantaloupe_helper.base_url(file_set)).to be_nil
      end
    end
    context "without generated derivatives" do
      before do
        allow(file_set).to receive(:pyramidal_derivative).and_return(nil)
        allow(file_set).to receive(:derivative_file).and_return(nil)
      end
      it "raises an Valkyrie::Persistence::ObjectNotFoundError" do
        expect { cantaloupe_helper.base_url(file_set) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
