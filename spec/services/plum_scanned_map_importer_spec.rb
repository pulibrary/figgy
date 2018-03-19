# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumScannedMapImporter do
  with_queue_adapter :inline
  subject(:importer) { described_class.new(id: id, change_set_persister: change_set_persister) }
  let(:id) { "ppc28d195m" }
  let(:change_set_persister) do
    PlumChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:plum_storage),
      characterize: false
    )
  end
  before do
    import_plum_record(id)
  end
  it "imports a Scanned Map" do
    allow(FileUtils).to receive(:mv).and_call_original
    output = nil
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      output = described_class.new(id: id, change_set_persister: buffered_changeset_persister).import!
    end
    expect(output.id).not_to be_blank
    expect(output.depositor).to eq ["eliotj"]
    expect(output.source_metadata_identifier).to be_nil
    expect(output.title[0].to_s).to eq "Tabula Asiae X"
    expect(output.state).to eq ["complete"]
    expect(output.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
    expect(output.read_groups).to eq ["public"]
    expect(output.local_identifier).to eq ["ppc28d195m", "PUmap_10927"]
    expect(output.member_of_collection_ids.length).to eq 0
    expect(output.identifier).to eq ["ark:/88435/3j3333761"]
    expect(output.viewing_hint).to eq ["individuals"]
    expect(output.coverage).to eq ["northlimit=37.1935; eastlimit=91.9053; southlimit=7.2976; westlimit=65.1118; units=degrees; projection=EPSG:4326"]
    expect(output.creator).to eq ["Sebastian Münster"]
    expect(output.publisher).to eq ["Heinrich Petri"]
    expect(output.spatial).to eq ["Asia", "India", "Bangladesh"]
    expect(output.subject).to eq ["Elevation", "Elevation and derived products", "Historical"]
    expect(output.temporal).to eq ["1540"]
    expect(output.member_ids.length).to eq 2

    members = query_service.find_members(resource: output).to_a
    expect(members[0].local_identifier).to eq ["pdr271f74s"]
    expect(members[0].original_file.width).to eq ["5712"]
    expect(members[0].original_file.height).to eq ["4347"]
    expect(members[0].original_file.checksum.count).to eq 1
    expect(members[0].original_file.checksum.first).to be_a MultiChecksum
    expect(members[0].derivative_file).not_to be_blank
    expect(members[0].derivative_file.file_identifiers[0].to_s).to include("/#{Figgy.config['derivative_path']}/")
    expect(members[0].title).to eq ["PUmap_10927"]
    expect(members[1].local_identifier).to eq ["pnz808g27r"]
    expect(members[1].title).to eq ["fgdc.xml"]
    expect(members[1].mime_type).to eq ["application/xml; schema=fgdc"]

    expect(output.thumbnail_id).to eq [members[0].id]
    expect(FileUtils).not_to have_received(:mv)
  end
  context "when given a map set" do
    let(:id) { "pz029rp965" }
    before do
      import_plum_record(id)
      stub_bibdata(bib_id: "5144620")
      stub_ezid(shoulder: "99999/fk4", blade: "5144620")
    end
    it "imports it" do
      output = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        output = described_class.new(id: id, change_set_persister: buffered_changeset_persister).import!
      end
      expect(output.id).not_to be_blank
      expect(output.source_metadata_identifier).to eq ["5144620"]
      expect(output.title.first.to_s).to eq "Mount Holly, N.J."
      expect(output.state).to eq ["complete"]
      expect(output.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
      expect(output.local_identifier).to eq ["pz029rp965"]
      expect(output.pdf_type).to eq ["gray"]
      expect(output.rights_statement).to eq [RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")]
      expect(output.rights_statement.first).to be_a RDF::URI
      expect(output.member_ids.length).to eq 2

      collections = query_service.find_references_by(resource: output, property: :member_of_collection_ids)
      expect(collections.flat_map(&:slug)).to contain_exactly "sanborn"
      expect(collections.flat_map(&:title)).to contain_exactly(
        "Sanborn Fire Insurance Maps of New Jersey"
      )
      expect(query_service.find_all_of_model(model: Collection).to_a.length).to eq 1

      members = query_service.find_members(resource: output).to_a
      expect(members[0]).to be_a ScannedMap
      expect(members[0].title.first.to_s).to eq "Mount Holly, N.J. (Sheet 1)."
      expect(members[0].visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED]
      expect(members[0].member_ids.length).to eq 1
      expect(members[1].title.first.to_s).to eq "Mount Holly, N.J. (Sheet 2)."
      expect(members[1].member_ids.length).to eq 1
      expect(output.thumbnail_id).to eq [members[0].member_ids.first]

      expect(query_service.find_all_of_model(model: ScannedMap).to_a.length).to eq 3
    end
  end

  describe '#logical_structure_from' do
    context 'when it fails to find a Plum Solr Document' do
      let(:logger) { instance_double(Logger) }
      before do
        allow(logger).to receive(:warn)
      end
      it 'logs a warning when the logical structure cannot be parsed' do
        importer = nil
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          importer = described_class.new(id: 'ps7529f138', change_set_persister: buffered_changeset_persister, logger: logger)
        end
        expect(importer.logical_structure_from(nil)).to be_empty
        expect(logger).to have_received(:warn).with(/Failed to parse the logical structure while importing /)
      end
    end
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
