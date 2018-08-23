# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe IngestIntermediateFileJob do
  describe "#perform" do
    let(:master_file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:file_path) { Rails.root.join("spec", "fixtures", "files", "abstract.tiff") }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [master_file]) }
    let(:adapter) { Valkyrie.config.metadata_adapter }

    it "ingests a file and appends it to an existing resource as an intermediate file" do
      described_class.perform_now(file_path: file_path, id: resource.id)
      updated_resource = adapter.query_service.find_by(id: resource.id)

      file_sets = updated_resource.decorate.file_sets
      expect(file_sets).not_to be_empty
      file_set = file_sets.first

      expect(file_set.file_metadata).not_to be_empty

      intermed_file_metadata = file_set.file_metadata.find { |metadata| metadata.use.include? Valkyrie::Vocab::PCDMUse.ServiceFile }
      expect(intermed_file_metadata).not_to be_nil

      expect(intermed_file_metadata.original_filename).to include "abstract.tiff"
      expect(intermed_file_metadata.use).to eq [Valkyrie::Vocab::PCDMUse.ServiceFile]
      expect(intermed_file_metadata.label).to include "abstract.tiff"
    end

    context "when the resource cannot be found" do
      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        allow(logger).to receive(:info)
        allow(logger).to receive(:error)
        allow(Valkyrie).to receive(:logger).and_return(logger)
      end

      it "logs and raises an error" do
        expect { described_class.perform_now(file_path: file_path, id: "invalid") }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        expect(logger).to have_received(:error).with(/IngestIntermediateFileJob\: Resource not found using ID\: invalid/)
      end
    end

    context "when using a bib. ID to retrieve the ingested resource" do
      let(:bib_id) { "123456" }
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: [bib_id],
                                         files: [master_file])
      end

      before do
        stub_bibdata(bib_id: bib_id)
        resource
        described_class.perform_now(file_path: file_path, property: :source_metadata_identifier, value: bib_id)
      end

      it "ingests a file and appends it to an existing resource as an intermediate file" do
        updated_resource = adapter.query_service.find_by(id: resource.id)

        file_sets = updated_resource.decorate.file_sets
        expect(file_sets).not_to be_empty
        file_set = file_sets.first

        expect(file_set.file_metadata).not_to be_empty

        intermed_file_metadata = file_set.file_metadata.find { |metadata| metadata.use.include? Valkyrie::Vocab::PCDMUse.ServiceFile }
        expect(intermed_file_metadata).not_to be_nil

        expect(intermed_file_metadata.original_filename).to include "abstract.tiff"
        expect(intermed_file_metadata.use).to eq [Valkyrie::Vocab::PCDMUse.ServiceFile]
        expect(intermed_file_metadata.label).to include "abstract.tiff"
      end
    end

    context "when appending an intermediate file to a multi-volume work" do
      let(:bib_id) { "123456" }
      let(:member_resource1) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: [bib_id],
                                         files: [master_file])
      end

      let(:member_resource2) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: [bib_id],
                                         files: [master_file])
      end

      let(:resource) do
        FactoryBot.create_for_repository(:scanned_resource,
                                         source_metadata_identifier: [bib_id],
                                         member_ids: [member_resource1.id, member_resource2.id])
      end

      before do
        stub_bibdata(bib_id: bib_id)
        resource
        described_class.perform_now(file_path: file_path, property: :source_metadata_identifier, value: bib_id)
      end

      it "ingests a file and appends it to each member of an existing resource as an intermediate file" do
        updated_resource = adapter.query_service.find_by(id: resource.id)

        updated_resource.decorate.volumes do |volume|
          file_sets = volume.decorate.file_sets
          expect(file_sets).not_to be_empty
          file_set = file_sets.first

          expect(file_set.file_metadata).not_to be_empty

          intermed_file_metadata = file_set.file_metadata.find { |metadata| metadata.use.include? Valkyrie::Vocab::PCDMUse.ServiceFile }
          expect(intermed_file_metadata).not_to be_nil

          expect(intermed_file_metadata.original_filename).to include "abstract.tiff"
          expect(intermed_file_metadata.use).to eq [Valkyrie::Vocab::PCDMUse.ServiceFile]
          expect(intermed_file_metadata.label).to include "abstract.tiff"
        end
      end
    end
  end
end
