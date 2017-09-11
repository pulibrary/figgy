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
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "applies remote metadata from bibdata" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain", language: :fr)]
      expect(output.primary_imported_metadata.creator).to eq ["Bord, Janet, 1945-"]
      expect(output.primary_imported_metadata.call_number).to eq ["BL980.G7 B66 1982"]
      expect(output.primary_imported_metadata.source_jsonld).not_to be_blank
    end
  end
  context "when a resource is completed" do
    let(:shoulder) { '99999/fk4' }
    let(:blade) { '123456' }

    before do
      stub_bibdata(bib_id: '123456')
      stub_ezid(shoulder: shoulder, blade: blade)
    end

    it "mints an ARK" do
      resource = FactoryGirl.create(:scanned_resource, title: [], source_metadata_identifier: '123456', state: 'final_review')
      change_set = change_set_class.new(resource)
      change_set.prepopulate!
      change_set.validate(state: 'complete')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)
      expect(output.identifier.first).to eq "ark:/#{shoulder}#{blade}"
    end
  end
  context "when a source_metadata_identifier is set and it's from PULFA" do
    before do
      stub_pulfa(pulfa_id: "MC016_c9616")
      stub_ezid(shoulder: "99999/fk4", blade: "MC016_c9616")
    end
    it "applies remote metadata from PULFA" do
      resource = FactoryGirl.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: 'MC016_c9616')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ['Series 5: Speeches, Statements, Press Conferences, Etc - 1953 - Speech: "... Results of the Eleventh Meeting of the Council of NATO"']
      expect(output.primary_imported_metadata.source_metadata).not_to be_blank
    end
  end
  context "when a source_metadata_identifier is set afterwards" do
    it "does not change anything" do
      resource = FactoryGirl.create_for_repository(:scanned_resource, title: 'Title', source_metadata_identifier: nil)
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456', title: [], refresh_remote_metadata: "0")
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to be_blank
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
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "applies remote metadata from bibdata" do
      resource = FactoryGirl.create_for_repository(:scanned_resource, title: 'Title', imported_metadata: [{ applicant: 'Test' }], source_metadata_identifier: nil)
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '123456', title: [], refresh_remote_metadata: "1")
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain", language: :fr)]
      expect(output.primary_imported_metadata.applicant).to be_blank
      expect(output.source_metadata_identifier).to eq ['123456']
    end
  end

  describe "uploading files" do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    it "can append files as FileSets", run_real_derivatives: true do
      resource = FactoryGirl.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)

      expect(members.to_a.length).to eq 1
      expect(members.first).to be_kind_of FileSet
      expect(output.thumbnail_id).to eq [members.first.id]

      file_metadata_nodes = members.first.file_metadata
      expect(file_metadata_nodes.to_a.length).to eq 2
      expect(file_metadata_nodes.first).to be_kind_of FileMetadata

      original_file_node = file_metadata_nodes.find { |x| x.use == [Valkyrie::Vocab::PCDMUse.OriginalFile] }

      expect(original_file_node.file_identifiers.length).to eq 1
      expect(original_file_node.width).to eq ["200"]
      expect(original_file_node.height).to eq ["287"]
      expect(original_file_node.mime_type).to eq ["image/tiff"]
      expect(original_file_node.checksum[0].sha256).to eq "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
      expect(original_file_node.checksum[0].md5).to eq "2a28fb702286782b2cbf2ed9a5041ab1"
      expect(original_file_node.checksum[0].sha1).to eq "1b95e65efc3aefeac1f347218ab6f193328d70f5"

      original_file = Valkyrie::StorageAdapter.find_by(id: original_file_node.file_identifiers.first)
      expect(original_file).to respond_to(:read)

      derivative_file_node = file_metadata_nodes.find { |x| x.use == [Valkyrie::Vocab::PCDMUse.ServiceFile] }

      expect(derivative_file_node).not_to be_blank
      derivative_file = Valkyrie::StorageAdapter.find_by(id: derivative_file_node.file_identifiers.first)
      expect(derivative_file).not_to be_blank
      expect(derivative_file.io.path).to start_with(Rails.root.join("tmp", "derivatives").to_s)

      expect(query_service.find_all.to_a.map(&:class)).to contain_exactly ScannedResource, FileSet
    end
  end
  describe "updating files" do
    let(:file1) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:file2) { fixture_file_upload('files/holding_locations.json', 'application/json') }
    it "can append files as FileSets", run_real_derivatives: true do
      # upload a file
      resource = FactoryGirl.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.files = [file1]
      output = change_set_persister.save(change_set: change_set)
      file_set = query_service.find_members(resource: output).first
      file_node = file_set.file_metadata.find { |x| x.use == [Valkyrie::Vocab::PCDMUse.OriginalFile] }
      file = storage_adapter.find_by(id: file_node.file_identifiers.first)
      expect(file.size).to eq 196_882

      # update the file
      change_set = FileSetChangeSet.new(file_set)
      change_set.files = [{ file_node.id.to_s => file2 }]
      change_set_persister.save(change_set: change_set)
      updated_file_set = query_service.find_by(id: file_set.id)
      updated_file_node = updated_file_set.file_metadata.find { |x| x.id == file_node.id }
      updated_file = storage_adapter.find_by(id: updated_file_node.file_identifiers.first)
      expect(updated_file.size).to eq 5600
    end
  end

  describe "collection interactions" do
    context "when a collection is deleted" do
      it "cleans up associations from all its members" do
        collection = FactoryGirl.create_for_repository(:collection)
        resource = FactoryGirl.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
        change_set = CollectionChangeSet.new(collection)

        change_set_persister.delete(change_set: change_set)
        reloaded = query_service.find_by(id: resource.id)

        expect(reloaded.member_of_collection_ids).to eq []
      end
    end
  end

  describe "deleting child SRs" do
    context "when a child is deleted" do
      it "cleans up associations" do
        child = FactoryGirl.create_for_repository(:scanned_resource)
        parent = FactoryGirl.create_for_repository(:scanned_resource, member_ids: child.id)
        change_set = ScannedResourceChangeSet.new(child)

        change_set_persister.delete(change_set: change_set)
        reloaded = query_service.find_by(id: parent.id)

        expect(reloaded.member_ids).to eq []
      end
    end
  end

  describe "setting visibility" do
    context "when setting to public" do
      it "adds the public read_group" do
        resource = FactoryGirl.build(:scanned_resource, read_groups: [])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: 'open')
        change_set.sync

        expect(change_set.model.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
    end
    context "when setting to princeton only" do
      it "adds the authenticated read_group" do
        resource = FactoryGirl.build(:scanned_resource, read_groups: [])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        change_set.sync

        expect(change_set.model.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end
    end
    context "when setting to private" do
      it "removes all read groups" do
        resource = FactoryGirl.build(:scanned_resource, read_groups: ['public'])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
        change_set.sync

        expect(change_set.model.read_groups).to eq []
      end
    end

    context "with existing member resources and file sets" do
      let(:resource1) { FactoryGirl.create_for_repository(:file_set) }
      let(:resource2) { FactoryGirl.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the access control policies" do
        resource = FactoryGirl.build(:scanned_resource, read_groups: [])
        resource.member_ids = [resource1.id, resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
        change_set.sync

        updated = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: updated)
        expect(members.first.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        expect(members.to_a.last.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
    end
  end

  describe "setting state" do
    context "with member resources and file sets" do
      let(:resource2) { FactoryGirl.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the workflow state" do
        resource = FactoryGirl.build(:scanned_resource, read_groups: [], state: 'open')
        resource.member_ids = [resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(state: 'open')
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)
        expect(members.first.state).to eq ['open']
      end
    end
  end

  describe "appending" do
    it "appends a child via #append_id" do
      parent = FactoryGirl.create_for_repository(:scanned_resource)
      resource = FactoryGirl.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(append_id: parent.id.to_s)
      change_set.sync

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)
      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:id-#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
    end
  end
end
