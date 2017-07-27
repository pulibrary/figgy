# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe PlumChangeSetPersister do
  subject(:change_set_persister) do
    described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_class) { ScannedResourceChangeSet }
  it_behaves_like "a Valkyrie::ChangeSetPersister"

  context "when a source_metadata_identifier is set for the first time" do
    before do
      stub_bibdata(bib_id: '123456')
    end
    it "applies remote metadata from bibdata" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain", language: :fr)]
      expect(output.creator).to eq ["Bord, Janet, 1945-"]
      expect(output.call_number).to eq ["BL980.G7 B66 1982"]
    end
  end
  context "when a source_metadata_identifier is set and it's from PULFA" do
    before do
      stub_pulfa(pulfa_id: "MC016_c9616")
    end
    it "applies remote metadata from PULFA" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: 'MC016_c9616')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to eq ['Series 5: Speeches, Statements, Press Conferences, Etc - 1953 - Speech: "... Results of the Eleventh Meeting of the Council of NATO"']
    end
  end
  context "when a source_metadata_identifier is set afterwards" do
    it "does not change anything" do
      resource = FactoryGirl.create_for_repository(:scanned_resource, title: 'Title', source_metadata_identifier: nil)
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456', title: [], refresh_remote_metadata: "0")
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to be_blank
    end
  end
  context "when a source_metadata_identifier is set for the first time, and it doesn't exist" do
    before do
      stub_bibdata(bib_id: '123456', status: 404)
    end
    it "is marked as invalid" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)

      expect(change_set.validate(source_metadata_identifier: '123456')).to eq false
    end
  end
  context "when a source_metadata_identifier is set for the first time, and it doesn't exist from PULFA" do
    before do
      stub_pulfa(pulfa_id: "MC016_c9616", body: '')
    end
    it "is marked as invalid" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)

      expect(change_set.validate(source_metadata_identifier: 'MC016_c9616')).to eq false
    end
  end
  context "when a source_metadata_identifier is set afterwards and refresh_remote_metadata is set" do
    before do
      stub_bibdata(bib_id: '123456')
    end
    it "applies remote metadata from bibdata" do
      resource = FactoryGirl.create_for_repository(:scanned_resource, title: 'Title', applicant: 'Test', source_metadata_identifier: nil)
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456', title: [], refresh_remote_metadata: "1")
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain", language: :fr)]
      expect(output.applicant).to be_blank
      expect(output.source_metadata_identifier).to eq ['123456']
    end
  end

  describe "uploading files" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    it "can append files as FileSets" do
      resource = FactoryGirl.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)

      expect(members.length).to eq 1
      expect(members[0]).to be_kind_of FileSet

      file_metadata_nodes = query_service.find_members(resource: members[0])
      expect(file_metadata_nodes.length).to eq 1
      expect(file_metadata_nodes[0]).to be_kind_of FileMetadata

      original_file_node = file_metadata_nodes[0]

      expect(original_file_node.file_identifiers.length).to eq 1
      original_file = Valkyrie::StorageAdapter.find_by(id: original_file_node.file_identifiers[0])
      expect(original_file.read).to eq file.read
    end
  end
end
