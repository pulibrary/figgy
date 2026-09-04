require "rails_helper"

RSpec.describe ManifestBuilder::ManifestHelper do
  subject(:helper) { described_class.new }

  let(:full_resolution) do
    FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid),
                     use: [::PcdmUse::ServiceFile],
                     mime_type: ["image/tiff"],
                     file_identifiers: ["disk://full.tif"])
  end
  let(:thumbnail) do
    FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid),
                     use: [::PcdmUse::ThumbnailServiceFile],
                     mime_type: ["image/tiff"],
                     file_identifiers: ["disk://thumbnail.tif"])
  end

  before do
    allow(helper).to receive(:manifest_image_path).and_return("http://example.com/base")
  end

  describe "#manifest_image_thumbnail_path" do
    context "when the file set has a thumbnail derivative" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [full_resolution, thumbnail]) }

      it "is uses it rather than the full-resolution one" do
        helper.manifest_image_thumbnail_path(file_set)
        expect(helper).to have_received(:manifest_image_path).with(file_set, thumbnail)
      end
    end

    context "when the file set only has a full-resolution tiff" do
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [full_resolution]) }

      it "the full-resolution one is used" do
        helper.manifest_image_thumbnail_path(file_set)
        expect(helper).to have_received(:manifest_image_path).with(file_set, nil)
      end
    end
  end
end
