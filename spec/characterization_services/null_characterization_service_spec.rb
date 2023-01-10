# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullCharacterizationService do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }

  context "with a mets file" do
    let(:mets_file) { fixture_file_upload("mets/pudl0001-4612596.mets", "application/xml; schema=mets") }
    describe "#valid?" do
      it "is valid" do
        resource = FactoryBot.create_for_repository(:scanned_resource, files: [mets_file])
        file_set = resource.decorate.members.first
        expect(described_class.new(file_set: file_set, persister: persister).valid?).to be true
      end
    end

    it "properly no-ops on a mets metadata file" do
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [mets_file])
      file_set = resource.decorate.members.first
      new_file_set = described_class.new(file_set: file_set, persister: persister).characterize(save: false)
      expect(new_file_set.original_file.mime_type).to eq ["application/xml; schema=mets"]
    end
  end

  context "with a tiff" do
    let(:tiff_file) { fixture_file_upload("files/example.tif", "image/tiff") }
    describe "#valid?" do
      it "returns false" do
        resource = FactoryBot.create_for_repository(:scanned_resource, files: [tiff_file])
        file_set = resource.decorate.members.first
        expect(described_class.new(file_set: file_set, persister: persister).valid?).to be false
      end
    end
  end

  context "with a pdf preservation file" do
    let(:pdf_file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
    describe "#valid?" do
      it "returns false" do
        resource = FactoryBot.create_for_repository(:scanned_resource, files: [pdf_file])
        file_set = resource.decorate.members.first
        pdf_file_metadata = file_set.file_metadata.first
        pdf_file_metadata.use = [Valkyrie::Vocab::PCDMUse.PreservationFile]
        file_set.file_metadata = [pdf_file_metadata]
        file_set = adapter.persister.save(resource: file_set)

        expect(described_class.new(file_set: file_set, persister: persister).valid?).to be false
      end
    end
  end
end
