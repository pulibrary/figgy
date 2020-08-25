# frozen_string_literal: true

require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe PDFCharacterizationService do
  it_behaves_like "a Valkyrie::Derivatives::FileCharacterizationService"
  # Required lets for shared specs.
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:valid_file_set) { Wayfinder.for(resource).file_sets.first }
  let(:persister) { ScannedResourcesController.change_set_persister.metadata_adapter.persister }
  let(:file_characterization_service) { described_class }

  before do
    output = "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
    ruby_mock = instance_double(Digest::SHA256, hexdigest: output)
    allow(Digest::SHA256).to receive(:hexdigest).and_return(ruby_mock)
  end

  it "characterizes a sample file" do
    file = fixture_file_upload("files/sample.pdf", "application/pdf")
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
    file_set = Wayfinder.for(resource).file_sets.first

    described_class.new(file_set: file_set, persister: persister).characterize(save: true)

    file_set = Wayfinder.for(resource).file_sets.first
    checksum = file_set.original_file.checksum
    expect(checksum.count).to eq 1
    expect(checksum.first).to be_a MultiChecksum
    expect(file_set.primary_file.page_count).to eq 2
  end
end
