# frozen_string_literal: true
require 'rails_helper'

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
        expect(helper.figgy_thumbnail_path(map)).to include 'full/!200,150/0/default.jpg'
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
        expect(helper.figgy_thumbnail_path(vector_resource)).to include valhalla.download_path(file_set.id, thumbnail_file_id)
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
        expect(helper.figgy_thumbnail_path(file_set)).to include valhalla.download_path(file_set.id, thumbnail_file_id)
      end
    end

    context "when encountering an error finding a derivative" do
      let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }

      before do
        allow(ManifestBuilder::ManifestHelper).to receive(:new).and_return(manifest_helper)
        allow(manifest_helper).to receive(:manifest_image_thumbnail_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it "generates a default image" do
        file_set = FactoryBot.create_for_repository(:file_set)
        book = FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: file_set.id)

        expect(helper.figgy_thumbnail_path(book)).to eq helper.image_tag("default.png")
      end
    end
  end
end
