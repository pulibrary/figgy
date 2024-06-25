# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe ManifestBuilderV3::CanvasBuilder do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(:scanned_resource, files: [file])
  end
  let(:file_set) { scanned_resource.decorate.file_sets.first }
  let(:record) { file_set }
  let(:parent) { scanned_resource }
  let(:root_node) { ManifestBuilderV3::RootNode.new(scanned_resource) }
  let(:builder) do
    described_class.new(
      ManifestBuilderV3::LeafNode.new(record, root_node),
      root_node,
      iiif_canvas_factory: ManifestBuilderV3::ManifestServiceLocator.iiif_canvas_factory,
      content_builder: ManifestBuilderV3::ManifestServiceLocator.content_builder,
      choice_builder: ManifestBuilderV3::ManifestServiceLocator.choice_builder,
      iiif_annotation_page_factory: ManifestBuilderV3::ManifestServiceLocator.iiif_annotation_page_factory
    )
  end
  let(:manifest) { ManifestBuilderV3::ManifestServiceLocator.iiif_manifest_factory.new }
  let(:canvases) { builder.apply([]) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

  context "when viewing a Scanned Resource" do
    before do
      file_set.viewing_hint = "individuals"
      file_set.local_identifier = "li1"
      persister.save(resource: file_set)
    end

    describe "#apply" do
      it "appends the transformed metadata to the Manifest" do
        expect(canvases).not_to be_empty
        canvas = canvases.first
        expect(canvas.label).to eq("eng" => ["example.tif"])
        expect(canvas.inner_hash["local_identifier"]).to eq "li1"
        expect(canvas.inner_hash["viewingHint"]).to eq "individuals"
        expect(canvas.items).not_to be_empty
        annotation_page = canvas.items.first

        expect(annotation_page.items).not_to be_empty
        annotation = annotation_page.items.first
        expect(annotation.body).to be_a IIIFManifest::V3::ManifestBuilder::IIIFManifest::Body
        expect(annotation.body.inner_hash["type"]).to eq "Image"
        expect(annotation.body.inner_hash["format"]).to eq "image/jpeg"
      end
    end

    describe "#label" do
      it "sets the label from the FileSet" do
        expect(builder.label).to eq ["example.tif"]
      end
    end
  end

  context "when generating a Canvas for a node in the logical structure" do
    let(:structure_node) { StructureNode.new(label: "structure label", proxy: file_set.id) }
    let(:leaf_structure_node) { ManifestBuilderV3::LeafStructureNode.new(structure_node) }
    let(:builder) do
      described_class.new(
        leaf_structure_node,
        ManifestBuilderV3::RootNode.new(scanned_resource),
        iiif_canvas_factory: ManifestBuilderV3::ManifestServiceLocator.iiif_canvas_factory,
        content_builder: ManifestBuilderV3::ManifestServiceLocator.content_builder,
        choice_builder: ManifestBuilderV3::ManifestServiceLocator.choice_builder,
        iiif_annotation_page_factory: ManifestBuilderV3::ManifestServiceLocator.iiif_annotation_page_factory
      )
    end

    describe "#label" do
      it "sets the label from the structure" do
        expect(builder.label).to eq ["structure label"]
      end
    end
  end

  describe "#rendering_builder" do
    it "delegates to the local rendering builder Class" do
      expect(builder.rendering_builder).to eq ManifestBuilderV3::CanvasRenderingBuilder
    end
  end
end
