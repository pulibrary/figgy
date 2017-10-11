# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumImporter do
  subject(:importer) { described_class.new(id: id, change_set_persister: change_set_persister) }
  let(:id) { "ps7529f137" }
  let(:change_set_persister) do
    PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:plum_storage),
      characterize: false
    )
  end
  before do
    import_plum_record(id)
    stub_bibdata(bib_id: "10068705")
  end
  it "imports a Scanned Resource" do
    allow(FileUtils).to receive(:mv).and_call_original
    output = nil
    # Create an existing collection to ensure duplicates aren't made.
    Valkyrie::MetadataAdapter.find(:indexing_persister).persister.save(
      resource: Collection.new(local_identifier: "pqb98np484", slug: "cotsen", title: "Treasures of the Cotsen Collection")
    )
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = described_class.new(id: id, change_set_persister: buffered_changeset_persister).import!
    end
    expect(output.id).not_to be_blank
    expect(output.depositor).to eq ["rmunoz"]
    expect(output.source_metadata_identifier).to eq ["10068705"]
    expect(output.title[0].to_s).to eq "Catalog, McLoughlin Bros., Inc., 1943 : children's reading, activity and novelty books"
    expect(output.state).to eq ["pending"]
    expect(output.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
    expect(output.read_groups).to eq []
    expect(output.member_ids.length).to eq 2
    expect(output.local_identifier).to eq ["ps7529f137"]
    expect(output.member_of_collection_ids.length).to eq 2
    expect(output.identifier).to eq ["ark:/88435/sx61dp92j"]

    collections = query_service.find_references_by(resource: output, property: :member_of_collection_ids)
    expect(collections.flat_map(&:slug)).to contain_exactly "cotsen", "pudl0139"
    expect(collections.flat_map(&:title)).to contain_exactly(
      "Treasures of the Cotsen Collection",
      "McLoughlin Publisher’s Catalogs, Advertising Materials, and “Publisher’s Archives” Items"
    )
    expect(query_service.find_all_of_model(model: Collection).to_a.length).to eq 2

    members = query_service.find_members(resource: output).to_a
    expect(members[1].local_identifier).to eq ["p7w62j794r"]
    expect(members[0].local_identifier).to eq ["p73669555b"]
    expect(members[0].original_file.width).to eq ["4686"]
    expect(members[0].original_file.height).to eq ["7200"]
    expect(members[0].derivative_file).not_to be_blank
    expect(members[0].derivative_file.file_identifiers[0].to_s).to include("/#{Figgy.config['derivative_path']}/")
    expect(output.thumbnail_id).to eq [members[1].id]
    expect(FileUtils).not_to have_received(:mv)

    # Ensure logical order works.
    expect(output.logical_structure[0]["label"]).to eq ["Logical"]
    expect(output.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
    expect(output.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
    expect(output.logical_structure[0].nodes[0].nodes[0].proxy).to eq [members[1].id]
  end
  context "when a derivative is missing" do
    before do
      import_plum_record("#{id}-broken")
      stub_bibdata(bib_id: "10068705")
    end
    it "generates it" do
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister.save(
        resource: Collection.new(local_identifier: "pqb98np484", slug: "cotsen", title: "Treasures of the Cotsen Collection")
      )
      output = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        output = described_class.new(id: id, change_set_persister: buffered_changeset_persister).import!
      end
      members = query_service.find_members(resource: output).to_a
      expect(members[0].derivative_file).not_to be_blank
    end
  end

  context "when given a multi volume work" do
    let(:id) { "p3b593k91p" }
    before do
      import_plum_record(id)
      stub_bibdata(bib_id: "3013481")
      stub_ezid(shoulder: "99999/fk4", blade: "3013481")
    end
    it "imports it" do
      output = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        output = described_class.new(id: id, change_set_persister: buffered_changeset_persister).import!
      end
      expect(output.id).not_to be_blank
      expect(output.source_metadata_identifier).to eq ["3013481"]
      expect(output.title.first.to_s).to start_with "Cabinet des"
      expect(output.state).to eq ["complete"]
      expect(output.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
      expect(output.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      expect(output.local_identifier).to eq ["p3b593k91p"]
      expect(output.pdf_type).to eq ["color"]
      expect(output.rights_statement).to eq [RDF::URI("http://rightsstatements.org/vocab/InC/1.0/")]
      expect(output.rights_statement.first).to be_a RDF::URI

      expect(output.member_ids.length).to eq 2

      members = query_service.find_members(resource: output).to_a
      expect(members[0]).to be_a ScannedResource
      expect(members[0].title).to eq ["01"]
      expect(members[0].visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED]
      expect(members[0].member_ids.length).to eq 1
      expect(members[1].title).to eq ["03"]
      expect(members[1].member_ids.length).to eq 1
      expect(output.thumbnail_id).to eq [members[0].id]

      expect(query_service.find_all_of_model(model: ScannedResource).to_a.length).to eq 3
    end
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
