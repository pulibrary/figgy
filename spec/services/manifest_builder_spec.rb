# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe ManifestBuilder do
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:scanned_resource) do
    FactoryGirl.create_for_repository(:scanned_resource,
                                      title: 'test title1',
                                      label: 'test label',
                                      actor: 'test person',
                                      sort_title: 'test title2',
                                      portion_note: 'test value1',
                                      rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
                                      call_number: 'test value2',
                                      edition: 'test edition',
                                      nav_date: 'test date',
                                      identifier: 'ark:/88435/abc1234de',
                                      imported_metadata: [{
                                        description: "Test Description"
                                      }],
                                      viewing_direction: ["right-to-left"])
  end
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file]) }
  let(:logical_structure) do
  end
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }

  def logical_structure(file_set_id)
    [
      {
        "label": "Table of Contents",
        "nodes": [
          {
            "label": "Chapter 1",
            "nodes": [
              {
                "label": "Chapter 1a",
                "nodes": [
                  {
                    "proxy": file_set_id
                  }
                ]
              }
            ]
          }
        ]
      }.deep_symbolize_keys
    ]
  end

  describe "#build" do
    before do
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids.first
      change_set = ScannedResourceChangeSet.new(output)
      change_set.validate(logical_structure: logical_structure(file_set_id))
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end

    it "generates a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["label"]).to eq ['test title1']
      expect(output["description"]).to eq "Test Description"
      expect(output["viewingHint"]).to eq "individuals"
      expect(output["viewingDirection"]).to eq "right-to-left"
      expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/abc1234de", "format" => "text/html"
      expect(output["sequences"].length).to eq 1
      canvas_id = output["sequences"][0]["canvases"][0]["@id"]
      expect(output["structures"].length).to eq 3
      structure_canvas_id = output["structures"][2]["canvases"][0]
      expect(canvas_id).to eq structure_canvas_id
      first_image = output["sequences"][0]["canvases"][0]["images"][0]
      expect(first_image["data"]).to eq nil
      expect(first_image["@type"]).to eq "oa:Annotation"
      expect(first_image["motivation"]).to eq "sc:painting"
      expect(first_image["resource"]["data"]).to eq nil
      expect(first_image["resource"]["service"]["@id"]).not_to be_nil
      expect(output["thumbnail"]).not_to be_blank
      expect(output["thumbnail"]["@id"]).to eq "#{first_image['resource']['service']['@id']}/full/!200,150/0/default.jpg"
      expect(output["thumbnail"]["service"]["@id"]).to eq first_image["resource"]["service"]["@id"]
    end

    context "when there's no derivative_file" do
      it "doesn't generate a IIIF endpoint" do
        allow_any_instance_of(FileSet).to receive(:derivative_file).and_return(nil)
        output = manifest_builder.build
        first_image = output["sequences"][0]["canvases"][0]["images"][0]
        expect(first_image["resource"]["service"]).to be_nil
      end
    end

    context "when a thumbnail_id doesn't exist" do
      let(:scanned_resource) do
        FactoryGirl.create_for_repository(:scanned_resource,
                                          title: 'test title1',
                                          label: 'test label',
                                          actor: 'test person',
                                          sort_title: 'test title2',
                                          portion_note: 'test value1',
                                          rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
                                          call_number: 'test value2',
                                          edition: 'test edition',
                                          nav_date: 'test date',
                                          identifier: 'ark:/88435/abc1234de',
                                          thumbnail_id: Valkyrie::ID.new("blablabla"),
                                          imported_metadata: [{
                                            description: "Test Description"
                                          }])
      end
      it "uses the first canvas as the thumbnail" do
        output = manifest_builder.build
        first_image = output["sequences"][0]["canvases"][0]["images"][0]
        expect(output["thumbnail"]).not_to be_blank
        expect(output["thumbnail"]["@id"]).to eq "#{first_image['resource']['service']['@id']}/full/!200,150/0/default.jpg"
      end
    end

    context "when in staging" do
      it "generates cantaloupe links" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)

        output = manifest_builder.build
        expect(output["sequences"][0]["canvases"][0]["images"][0]["resource"]["service"]["@id"]).to start_with "http://localhost:8182/iiif/2/"
      end
    end

    it 'generates a IIIF document with metadata' do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output).to include 'metadata'
      metadata = output["metadata"]
      expect(metadata).to be_kind_of Array
      expect(metadata.length).to eq(11)

      metadata_object = metadata.shift
      expect(metadata_object).to be_kind_of Hash

      expect(metadata_object["label"]).to eq 'Created At'
      metadata_values = metadata_object['value']
      expect(metadata_values).to be_kind_of Array
      metadata_value = metadata_values.shift
      expect { Date.strptime(metadata_value, '%m/%d/%y') }.not_to raise_error

      metadata_object = metadata.shift
      expect(metadata_object).to be_kind_of Hash

      expect(metadata_object["label"]).to eq 'Updated At'
      metadata_values = metadata_object['value']
      expect(metadata_values).to be_kind_of Array
      metadata_value = metadata_values.shift
      expect { Date.strptime(metadata_value, '%m/%d/%y') }.not_to raise_error

      metadata_object = metadata.shift
      expect(metadata_object).to be_kind_of Hash

      expect(metadata_object["label"]).to eq 'Portion Note'
      metadata_values = metadata_object['value']
      expect(metadata_values).to be_kind_of Array
      expect(metadata_values).to include 'test value1'
    end

    context "when the resource has multiple titles" do
      let(:scanned_resource) do
        FactoryGirl.create_for_repository(:scanned_resource, title: ['title1', 'title2'])
      end
      it "uses an array" do
        output = manifest_builder.build
        expect(output["label"]).to eq ['title1', 'title2']
      end
    end
  end

  context "when given a nested child" do
    let(:scanned_resource) do
      FactoryGirl.create_for_repository(:scanned_resource,
                                        member_ids: child.id,
                                        identifier: 'ark:/88435/5m60qr98h',
                                        viewing_direction: "right-to-left")
    end
    let(:child) { FactoryGirl.create_for_repository(:scanned_resource, files: [file]) }
    it "builds a IIIF collection" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["viewingHint"]).to eq "multi-part"
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{child.id}/manifest"
      expect(output["manifests"][0]["viewingHint"]).to be_nil
      expect(output["manifests"][0]["metadata"]).to be_nil
      expect(output["seeAlso"]).to include "@id" => "http://www.example.com/catalog/#{scanned_resource.id}.jsonld", "format" => "application/ld+json"
      expect(output["rendering"]).to include "@id" => "http://arks.princeton.edu/ark:/88435/5m60qr98h", "format" => "text/html"
      expect(output["license"]).to eq "http://rightsstatements.org/vocab/NKC/1.0/"
      # not allowed in collections until iiif presentation api v3
      expect(output["viewingDirection"]).to eq nil
    end
  end

  context "when given a scanned map" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryGirl.create_for_repository(:scanned_map, description: "Test Description")
    end
    let(:change_set) { ScannedMapChangeSet.new(scanned_map, files: [file]) }
    before do
      output = change_set_persister.save(change_set: change_set)
      change_set = ScannedMapChangeSet.new(output)
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq "Test Description"
      expect(output["sequences"][0]["canvases"][0]["images"].length).to eq 1
    end
  end

  context "when given an ephemera project" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: ephemera_project.id)) }
    let(:ephemera_project) do
      FactoryGirl.create_for_repository(:ephemera_project, member_ids: [box.id, ephemera_term.id, folder2.id])
    end
    let(:ephemera_term) { FactoryGirl.create_for_repository(:ephemera_term) }
    let(:box) { FactoryGirl.create_for_repository(:ephemera_box, member_ids: folder.id) }
    let(:folder) { FactoryGirl.create_for_repository(:ephemera_folder) }
    let(:folder2) { FactoryGirl.create_for_repository(:ephemera_folder, member_ids: folder3.id) }
    let(:folder3) { FactoryGirl.create_for_repository(:ephemera_folder) }
    let(:change_set) { EphemeraProjectChangeSet.new(ephemera_project) }
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [ephemera_project.decorate.slug]
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder.id}/manifest"
      expect(output["manifests"][1]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder2.id}/manifest"
      expect(output["manifests"].length).to eq 2
    end
  end

  context "when given a collection" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: collection.id)) }
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:change_set) { CollectionChangeSet.new(collection) }
    let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id]) }

    before do
      scanned_resource
      output = change_set_persister.save(change_set: change_set)
      change_set = CollectionChangeSet.new(output)
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [collection.decorate.slug]
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{scanned_resource.id}/manifest"
      expect(output["viewingDirection"]).to eq nil
    end
  end
end
