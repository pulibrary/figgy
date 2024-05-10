# frozen_string_literal: true

require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe PDFCharacterizationService do
  it_behaves_like "a Valkyrie::Derivatives::FileCharacterizationService"
  # Required lets for shared specs.
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:valid_file_set) { Wayfinder.for(resource).file_sets.first }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file_characterization_service) { described_class }

  before do
    output = "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
    ruby_mock = instance_double(Digest::SHA256, hexdigest: output)
    allow(Digest::SHA256).to receive(:hexdigest).and_return(ruby_mock)
  end

  it "characterizes a sample file" do
    described_class.new(file_set: valid_file_set, persister: persister).characterize(save: true)

    file_set = Wayfinder.for(resource).file_sets.first
    checksum = file_set.original_file.checksum
    expect(checksum.count).to eq 1
    expect(checksum.first).to be_a MultiChecksum
    expect(file_set.primary_file.page_count).to eq 2
  end

  context "when a file set contains a preservation file and an intermediate file" do
    it "characterizes both files" do
      preservation = fixture_file_with_use("files/sample.pdf", "application/pdf", ::PcdmUse::PreservationFile)
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [preservation])
      file_set = query_service.find_members(resource: resource).first
      IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "sample.pdf"), file_set_id: file_set.id)
      file_set = query_service.find_members(resource: resource).first
      expect(file_set.file_metadata[0].checksum).not_to be_empty
      expect(file_set.file_metadata[1].checksum).not_to be_empty
    end
  end

  context "when provided with a file that can not be characterized", run_real_characterization: true do
    let(:file) { fixture_file_upload("files/invalid.pdf", "application/pdf") }
    it "adds an error message to the file set and raises an error" do
      invalid_file_set = Wayfinder.for(resource).file_sets.first
      expect { described_class.new(file_set: invalid_file_set, persister: persister).characterize }.to raise_error(RuntimeError)
      file_set = query_service.find_by(id: invalid_file_set.id)
      expect(file_set.file_metadata[0].width).to be_empty
      expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
    end
  end

  context "when characterization fails and then succeeds" do
    it "removes any previous error messages" do
      allow(Vips::Image).to receive(:pdfload).and_raise("Error")
      expect { described_class.new(file_set: valid_file_set, persister: persister).characterize }.to raise_error(RuntimeError)
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
      allow(Vips::Image).to receive(:pdfload).and_call_original
      described_class.new(file_set: file_set, persister: persister).characterize
      file_set = query_service.find_by(id: valid_file_set.id)
      expect(file_set.file_metadata[0].error_message).to be_empty
    end
  end
end
