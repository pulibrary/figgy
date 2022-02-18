# frozen_string_literal: true

require "rails_helper"

RSpec.describe ThumbnailHelper do
  describe "#figgy_thumbnail_path" do
    context "when given a two-level deep scanned resource" do
      before do
        allow(Valkyrie.logger).to receive(:warn).and_return(nil)
      end

      it "uses the fileset thumbnail ID" do
        file_set = FactoryBot.create_for_repository(:file_set)
        book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: file_set.id)
        parent_book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: book.id)

        expect(helper.figgy_thumbnail_path(parent_book)).to include file_set.id.to_s
      end
      it "returns nothing when the fileset doesn't exist" do
        book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: Valkyrie::ID.new("busted"))
        parent_book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: book.id)

        expect(helper.figgy_thumbnail_path(parent_book)).to eq nil
      end
    end

    context "when given a scanned map" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      let(:map) { FactoryBot.create_for_repository(:scanned_map, thumbnail_id: file_set.id) }

      it "returns a iiif url" do
        expect(helper.figgy_thumbnail_path(map)).to include "full/!200,150/0/default.jpg"
      end
    end

    context "when given a vector resource" do
      let(:thumbnail_file_id) { Valkyrie::ID.new("test_id") }
      let(:thumbnail_file) { FileMetadata.new(id: thumbnail_file_id, use: [Valkyrie::Vocab::PCDMUse.ThumbnailImage]) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [thumbnail_file]) }
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: file_set.id, member_ids: [file_set.id]) }

      before do
        allow(file_set).to receive(:parent).and_return(vector_resource)
      end

      it "returns the path to the thumbnail derivative image" do
        expect(helper.figgy_thumbnail_path(vector_resource)).to include download_path(file_set.id, thumbnail_file_id)
      end
    end

    context "when given a fileset with a vector resource parent" do
      let(:thumbnail_file_id) { Valkyrie::ID.new("test_id") }
      let(:thumbnail_file) { FileMetadata.new(id: thumbnail_file_id, use: [Valkyrie::Vocab::PCDMUse.ThumbnailImage]) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [thumbnail_file]) }
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: file_set.id, member_ids: [file_set.id]) }

      before do
        allow(file_set).to receive(:parent).and_return(vector_resource)
      end

      it "returns the path to the thumbnail derivative image" do
        expect(helper.figgy_thumbnail_path(file_set)).to include download_path(file_set.id, thumbnail_file_id)
      end
    end

    context "when encountering an error finding a scanned resource derivative" do
      let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }

      before do
        allow(ManifestBuilder::ManifestHelper).to receive(:new).and_return(manifest_helper)
        allow(manifest_helper).to receive(:manifest_image_thumbnail_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it "generates a default image" do
        file_set = FactoryBot.create_for_repository(:file_set)
        book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: file_set.id)

        expect(helper.figgy_thumbnail_path(book)).to eq helper.image_tag "default.png", class: "thumbnail-inner"
      end
    end

    context "when encountering an error finding a vector resource derivative" do
      let(:thumbnail_file_id) { Valkyrie::ID.new("test_id") }
      let(:thumbnail_file) { FileMetadata.new(id: thumbnail_file_id, use: [Valkyrie::Vocab::PCDMUse.ThumbnailImage]) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [thumbnail_file]) }
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: file_set.id, member_ids: [file_set.id]) }

      before do
        allow(Valkyrie.config.metadata_adapter.query_service).to receive(:find_by).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(file_set).to receive(:parent).and_return(vector_resource)
      end

      it "generates a default image" do
        expect(helper.figgy_thumbnail_path(vector_resource)).to eq helper.image_tag "default.png", class: "thumbnail-inner"
      end
    end

    context "when an error is raised by the QueryService while trying to retrieve the resource" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      let(:book) { FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: file_set.id) }

      before do
        allow(Rails.logger).to receive(:error)
        book
        allow(Valkyrie.config.metadata_adapter.query_service).to receive(:find_by).and_raise(TypeError, "can't convert String into Hash")
      end

      it "logs an error and generates the markup for the default thumbnail" do
        expect(helper.figgy_thumbnail_path(book)).to eq helper.default_icon_fallback
        expect(Rails.logger).to have_received(:error).with("Unable to retrieve the resource with the ID #{book.id}")
      end
    end

    context "when the resource does not link to thumbnail ID but its first member does" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:member1) { FactoryBot.create_for_repository(:scanned_resource, files: [file1]) }
      let(:scanned_record1) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id]) }

      it "retrieves the thumbnail from the first member" do
        expect(helper.figgy_thumbnail_path(scanned_record1)).to eq helper.figgy_thumbnail_path(member1)
      end
    end

    context "when the resource does not link to thumbnail ID but its last member does" do
      let(:file1) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:member1) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:member2) { FactoryBot.create_for_repository(:scanned_resource, files: [file1]) }
      let(:scanned_record1) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id]) }

      it "retrieves the thumbnail from the last member" do
        expect(helper.figgy_thumbnail_path(scanned_record1)).to eq helper.figgy_thumbnail_path(member2)
      end
    end

    context "when the resource does not link to thumbnail ID and none of its members do" do
      let(:member1) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:member2) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:scanned_record1) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member1.id, member2.id]) }

      it "retrieves no thumbnail" do
        expect(helper.figgy_thumbnail_path(scanned_record1)).to eq nil
      end
    end
  end

  describe "#geo_file_set" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set) }
    let(:raster_resource) { FactoryBot.create_for_repository(:raster_resource, thumbnail_id: file_set.id) }
    let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: raster_resource.id) }

    context "without a thumbnail" do
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: nil) }
      it "return a nil value" do
        expect(helper.geo_file_set(vector_resource)).to be nil
      end
    end
    context "with a deleted thumbnail" do
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: "no-exist") }
      it "return a nil value" do
        expect(helper.geo_file_set(vector_resource)).to be nil
      end
    end
    context "with a valid thumbnail" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set) }
      let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource, thumbnail_id: file_set.id) }
      it "accesses the thumbnail" do
        expect(helper.geo_file_set(vector_resource)).to be_a FileSet
      end
    end

    it "accesses the thumbnail from the related geo resource" do
      expect(helper.geo_file_set(vector_resource)).to be_a FileSet
    end
  end
end
