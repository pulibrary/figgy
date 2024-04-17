# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:query_service) { ChangeSetPersister.default.query_service }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource,
                                     member_ids: child.id,
                                     identifier: "ark:/88435/5m60qr98h",
                                     viewing_direction: "right-to-left")
  end
  let(:child) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  it "builds a IIIF collection" do
    output = manifest_builder.build
    expect(output).to be_kind_of Hash
    expect(output["@type"]).to eq "sc:Collection"
    expect(output["viewingHint"]).to eq "multi-part"

    expect(output["thumbnail"]).to include "@id" => "http://www.example.com/image-service/#{child.member_ids.first.id}/full/!200,150/0/default.jpg"

    expect(output["manifests"].length).to eq 1
    expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{child.id}/manifest"
    expect(output["manifests"][0]["viewingHint"]).to be_nil
    expect(output["manifests"][0]["metadata"]).to be_nil
    expect(output["seeAlso"]).to include "@id" => "http://www.example.com/catalog/#{scanned_resource.id}.jsonld", "format" => "application/ld+json"
    expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/5m60qr98h", "format" => "text/html"
    expect(output["license"]).to eq RightsStatements.no_known_copyright.to_s
    # not allowed in collections until iiif presentation api v3
    expect(output["viewingDirection"]).to eq nil
    expect(output["manifests"][0]["thumbnail"]["@id"]).to eq "http://www.example.com/image-service/#{child.member_ids.first}/full/!200,150/0/default.jpg"
  end
  context "when the nested child does't have a valid thumbnail" do
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, thumbnail_id: ["invalid-id"]) }

    it "does not generate the thumbnail" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["viewingHint"]).to eq "multi-part"
      expect(output).not_to include "thumbnail"
    end
  end
end
