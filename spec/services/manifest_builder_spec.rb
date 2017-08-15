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
                                      nav_date: 'test date')
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
      expect(output["viewingHint"]).to eq "individuals"
      expect(output["sequences"].length).to eq 1
      canvas_id = output["sequences"][0]["canvases"][0]["@id"]
      expect(output["structures"].length).to eq 3
      structure_canvas_id = output["structures"][2]["canvases"][0]
      expect(canvas_id).to eq structure_canvas_id
    end

    it 'generates a IIIF document with metadata' do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output).to include 'metadata'
      metadata = output["metadata"]
      expect(metadata).to be_kind_of Array
      expect(metadata.length).to eq(10)

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

      expect(metadata_object["label"]).to eq 'Sort Title'
      metadata_values = metadata_object['value']
      expect(metadata_values).to be_kind_of Array
      expect(metadata_values).to include 'test title2'
    end
  end
  context "when given a nested child" do
    let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource, member_ids: child.id) }
    let(:child) { FactoryGirl.create_for_repository(:scanned_resource, files: [file]) }
    it "builds a IIIF collection" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_resources/#{child.id}/manifest"
    end
  end
end
