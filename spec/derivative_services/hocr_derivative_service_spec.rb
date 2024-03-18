# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe HocrDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:thumbnail) { Valkyrie::Vocab::PCDMUse.ThumbnailImage }
  let(:derivative_service) do
    HocrDerivativeService::Factory.new(change_set_persister: change_set_persister, processor_factory: processor_factory)
  end
  let(:processor_factory) { HocrDerivativeService::TesseractProcessor }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new(ocr_language: "eng"), files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given a parent without an hocr_language set" do
      let(:scanned_resource) do
        change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new(ocr_language: []), files: [file]))
      end
      it "is invalid" do
        is_expected.not_to be_valid
      end
    end

    context "when given a tiff mime_type" do
      it { is_expected.to be_valid }
    end

    context "when given a jpeg mime_type" do
      it "is valid" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.to be_valid
      end
    end

    context "when given a png mime_type" do
      it "is valid" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/png"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.to be_valid
      end
    end

    context "when given an invalid mime_type" do
      it "does not validate" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/not-valid"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end
  end

  context "tiff source" do
    let(:hocr_content) { File.read(Rails.root.join("spec", "fixtures", "hocr.hocr")) }
    let(:ocr_content) { File.read(Rails.root.join("spec", "fixtures", "ocr.txt")) }
    let(:service) { derivative_service.new(id: valid_change_set.id) }
    before do
      processor = instance_double(processor_factory)
      allow(processor_factory).to receive(:new).and_return(processor)
      result = HocrDerivativeService::TesseractProcessor::Result.new(hocr_content: hocr_content)
      allow(processor).to receive(:run!).and_return(result)
    end
    it "creates an HOCR file and attaches it as a property to the fileset" do
      service.create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
      expect(reloaded.ocr_content).not_to be_blank
      expect(reloaded.hocr_content.first).to eq hocr_content
      expect(reloaded.ocr_content.first).to eq ocr_content.strip
    end
  end

  context "jpeg source" do
    let(:file) { fixture_file_upload("files/large-jpg-test.jpg", "image/jpeg") }
    it "creates an HOCR file and attaches it to the fileset" do
      derivative_service.new(id: valid_change_set.id).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
    end
  end

  context "png source" do
    let(:file) { fixture_file_upload("files/abstract.png", "image/png") }
    it "creates an HOCR file and attaches it to the fileset" do
      derivative_service.new(id: valid_change_set.id).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
    end
  end

  context "ephemera folder" do
    let(:ephemera_folder) do
      change_set_persister.save(change_set: EphemeraFolderChangeSet.new(EphemeraFolder.new(ocr_language: "eng", state: "complete"), files: [file]))
    end
    let(:folder_members) { query_service.find_members(resource: ephemera_folder) }
    let(:valid_resource) { folder_members.first }
    let(:valid_change_set) { ChangeSet.for(valid_resource) }

    let(:hocr_content) { File.read(Rails.root.join("spec", "fixtures", "hocr.hocr")) }
    let(:ocr_content) { File.read(Rails.root.join("spec", "fixtures", "ocr.txt")) }
    let(:service) { derivative_service.new(id: valid_change_set.id) }
    before do
      processor = instance_double(processor_factory)
      allow(processor_factory).to receive(:new).and_return(processor)
      result = HocrDerivativeService::TesseractProcessor::Result.new(hocr_content: hocr_content)
      allow(processor).to receive(:run!).and_return(result)
    end
    it "creates an HOCR file and attaches it as a property to the fileset" do
      service.create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.hocr_content).not_to be_blank
      expect(reloaded.ocr_content).not_to be_blank
      expect(reloaded.hocr_content.first).to eq hocr_content
      expect(reloaded.ocr_content.first).to eq ocr_content.strip
    end
  end
end
