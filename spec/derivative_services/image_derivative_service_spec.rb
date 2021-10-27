# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe ImageDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ImageDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:decorated_scanned_maps) { query_service.find_members(resource: scanned_map) }
  let(:valid_resource) { decorated_scanned_maps.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given a valid mime_type" do
      it { is_expected.to be_valid }
    end
  end

  context "with an existing TIFF intermediate file", run_real_derivatives: true do
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:valid_resource) { scanned_resource.decorate.members.first }
    let(:valid_change_set) { ChangeSet.for(valid_resource) }
    let(:intermediate_file) { double("File") }

    before do
      allow(intermediate_file).to receive(:original_filename).and_return("00000001.tif")
      allow(intermediate_file).to receive(:content_type).and_return("image/tiff")
      allow(intermediate_file).to receive(:use).and_return(Valkyrie::Vocab::PCDMUse.IntermediateFile)
      allow(intermediate_file).to receive(:path).and_return(
        Rails.root.join("spec", "fixtures", "files", "abstract.tiff")
      )

      file_set = scanned_resource.decorate.members.first
      change_set = FileSetChangeSet.new(file_set)
      change_set.validate(files: [intermediate_file])
      change_set_persister.save(change_set: change_set)
    end

    it "creates a JPEG thumbnail and attaches it to the fileset" do
      derivative_service.new(id: valid_change_set.id).create_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.length).to eq(3)

      expect(reloaded.thumbnail_files).not_to be_empty
      thumbnail = reloaded.thumbnail_files.first

      thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnail.file_identifiers.first)

      expect(thumbnail_file.read).not_to be_blank
    end
  end

  context "with a scanned map tif" do
    it "creates a JPEG thumbnail and attaches it to the fileset" do
      derivative_service.new(id: valid_change_set.id).create_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      thumbnail = reloaded.thumbnail_files.first
      expect(thumbnail).to be_present
      thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnail.file_identifiers.first)
      image = MiniMagick::Image.open(thumbnail_file.disk_path)
      expect(image.width).to eq 200
      expect(image.height).to eq 287
    end
  end

  context "with a malformed scanned map tiff" do
    let(:file) { fixture_file_upload("files/bad.tif", "image/tiff") }

    it "stores an error message on the fileset" do
      expect { derivative_service.new(id: valid_change_set.id).create_derivatives }.to raise_error(MiniMagick::Invalid)
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include(/bad magic number/)
    end
  end

  describe "#cleanup_derivatives" do
    before do
      derivative_service.new(id: valid_change_set.id).create_derivatives
    end

    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select { |file| (file.derivative? || file.thumbnail_file?) && file.mime_type.include?(image_mime_type) }).to be_empty
    end

    it "deletes the error_message" do
      resource = query_service.find_by(id: valid_resource.id)
      resource.original_file.error_message = ["it went poorly"]
      persister.save(resource: resource)
      derivative_service.new(id: resource.id).cleanup_derivatives

      resource = query_service.find_by(id: valid_resource.id)
      expect(resource.original_file.error_message).to be_empty
    end

    context "with an intermediate file" do
      it "deletes the error_message" do
        resource = query_service.find_by(id: valid_resource.id)
        resource.original_file.error_message = ["it went poorly"]
        # turn it into an intermediate file
        resource.original_file.use = [Valkyrie::Vocab::PCDMUse.IntermediateFile]
        persisted = persister.save(resource: resource)
        expect(persisted.intermediate_files.first.error_message).not_to be_empty

        derivative_service.new(id: resource.id).cleanup_derivatives

        resource = query_service.find_by(id: valid_resource.id)
        expect(resource.intermediate_files.first.error_message).to be_empty
      end
    end
  end
end
