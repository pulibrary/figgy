require "rails_helper"

RSpec.describe GeoDiscovery::DocumentBuilder::DocumentPath do
  subject(:document_path) { described_class.new(resource.decorate) }

  let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }
  let(:geo_vector_file) do
    FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid), use: [::PcdmUse::OriginalFile],
                     mime_type: [ControlledVocabulary.for(:geo_vector_format).all.first.value])
  end
  let(:pyramidal_file) do
    FileMetadata.new(id: Valkyrie::ID.new(SecureRandom.uuid), use: [::PcdmUse::ServiceFile],
                     mime_type: ["image/tiff"], file_identifiers: ["disk://full.tif"])
  end
  let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [geo_vector_file, pyramidal_file]) }
  let(:resource) { FactoryBot.create_for_repository(:vector_resource, member_ids: [file_set.id]) }

  before do
    allow(ManifestBuilder::ManifestHelper).to receive(:new).and_return(manifest_helper)
  end

  describe "#thumbnail" do
    context "when the pyramidal derivative can't be found" do
      before do
        allow(manifest_helper).to receive(:manifest_image_thumbnail_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it "returns nil rather than raising and error" do
        expect(document_path.thumbnail).to be_nil
      end
    end
  end
end
