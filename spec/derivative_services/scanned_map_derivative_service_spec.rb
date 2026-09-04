require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe ScannedMapDerivativeService do
  with_queue_adapter :inline
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ScannedMapDerivativeService::Factory.new(change_set_persister: change_set_persister)
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

    context "when given a tiff mime_type" do
      it { is_expected.to be_valid }
    end

    context "when given a jpeg mime_type" do
      it "is valid" do
        allow(valid_file).to receive(:mime_type).and_return(["image/jpeg"])
        is_expected.to be_valid
      end
    end

    context "when given a png mime_type" do
      it "is valid" do
        allow(valid_file).to receive(:mime_type).and_return(["image/png"])
        is_expected.to be_valid
      end
    end

    context "when given an invalid mime_type" do
      it "does not validate" do
        allow(valid_file).to receive(:mime_type).and_return(["image/gif"])
        is_expected.not_to be_valid
      end
    end
  end

  it "creates a pyramidal tiff" do
    resource = query_service.find_by(id: valid_resource.id)
    expect(resource.pyramidal_derivative).not_to be_blank
    expect(resource.file_metadata.select(&:thumbnail_file?)).to be_empty
  end

  describe "the pyramidal thumbnail derivative" do
    it "it is generated in addition to the fullsize pyramidal derivative" do
      resource = query_service.find_by(id: valid_resource.id)
      full_resolution = resource.pyramidal_derivative
      thumbnail = resource.pyramidal_thumbnail

      expect(thumbnail).not_to be_nil
      expect(thumbnail.id).not_to eq full_resolution.id
      expect(thumbnail.use).to eq [::PcdmUse::ThumbnailServiceFile]
      expect(thumbnail.mime_type).to eq ["image/tiff"]
      expect(full_resolution.use).to eq [::PcdmUse::ServiceFile]
    end

    it "is removed by cleanup_thumbnail_derivatives" do
      derivative_service.new(id: valid_change_set.id).cleanup_thumbnail_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.pyramidal_thumbnail).to be_nil
      expect(reloaded.file_metadata.select(&:thumbnail_file?)).to be_empty
      expect(reloaded.pyramidal_derivative).not_to be_nil
    end
  end

  context "when given a bad tiff" do
    let(:file) { fixture_file_upload("files/bad.tif", "image/tiff") }

    it "stores an error message on the fileset" do
      expect { derivative_service.new(id: valid_change_set.id).create_derivatives }.to raise_error(::Vips::Error)
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include(/Not a TIFF/)
    end
  end

  describe "#create_thumbnail_derivatives" do
    it "regenerates the thumbnail without rebuilding other derivatives" do
      resource = query_service.find_by(id: valid_resource.id)
      original_pyramidal = resource.pyramidal_derivative
      original_thumbnail = resource.pyramidal_thumbnail

      derivative_service.new(id: valid_resource.id).cleanup_thumbnail_derivatives
      derivative_service.new(id: valid_resource.id).create_thumbnail_derivatives

      reloaded = query_service.find_by(id: valid_resource.id)

      expect(reloaded.pyramidal_derivative.id).to eq original_pyramidal.id
      expect(reloaded.pyramidal_thumbnail.id).not_to eq original_thumbnail.id
      expect(reloaded.file_metadata.count(&:thumbnail_derivative?)).to eq 1
    end
  end

  describe "#cleanup_thumbnail_derivatives" do
    it "only deletes the thumbnail" do
      derivative_service.new(id: valid_change_set.id).cleanup_thumbnail_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:thumbnail_file?)).to be_empty
      expect(reloaded.pyramidal_derivative).not_to be_blank
    end
  end

  describe "#cleanup_derivatives" do
    it "deletes the attached fileset when the resource is deleted" do
      derivative_service.new(id: valid_change_set.id).cleanup_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      expect(reloaded.file_metadata.select(&:derivative?)).to be_empty
    end

    it "deletes the error_message" do
      resource = query_service.find_by(id: valid_resource.id)
      resource.original_file.error_message = ["Testing this"]
      persister.save(resource: resource)
      derivative_service.new(id: resource.id).cleanup_derivatives

      resource = query_service.find_by(id: valid_resource.id)
      expect(resource.original_file.error_message).to be_empty
    end
  end
end
