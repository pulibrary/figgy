# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'
include ActionDispatch::TestProcess

RSpec.describe PlumChangeSetPersister do
  with_queue_adapter :inline
  subject(:change_set_persister) do
    described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
  end

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_class) { ScannedResourceChangeSet }

  it_behaves_like "a Valkyrie::ChangeSetPersister"

  context "when a source_metadata_identifier is set for the first time on a scanned resource" do
    before do
      stub_bibdata(bib_id: '123456')
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "applies remote metadata from bibdata to an imported metadata resource" do
      resource = FactoryBot.build(:scanned_resource, title: [])
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
  context "when a source_metadata_identifier is set for the first time on a map image" do
    let(:change_set_class) { ScannedMapChangeSet }
    before do
      stub_bibdata(bib_id: '6592452')
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "applies remote metadata from bibdata directly to the resource" do
      resource = FactoryBot.build(:scanned_map, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: '6592452')
      change_set.sync
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to eq ["Brazil, Uruguay, Paraguay & Guyana"]
      expect(output.creator).to eq ["Bartholomew, John, 1805-1861"]
      expect(output.subject).to eq ["Brazil—Maps", "Guiana—Maps", "Paraguay—Maps", "Uruguay—Maps"]
      expect(output.spatial).to eq ["Brazil", "Uruguay", "Paraguay", "Guyana"]
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
      resource = FactoryBot.create(:scanned_resource, title: [], source_metadata_identifier: '123456', state: 'final_review')
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
      resource = FactoryBot.build(:scanned_resource, title: [])
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
      resource = FactoryBot.create_for_repository(:scanned_resource, title: 'Title', source_metadata_identifier: nil)
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
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)

      expect(change_set.validate(source_metadata_identifier: '123456')).to eq false
    end
  end
  context "when a source_metadata_identifier is set for the first time, and it doesn't exist from PULFA" do
    before do
      stub_pulfa(pulfa_id: "MC016_c9616", body: '')
    end
    it "is marked as invalid" do
      resource = FactoryBot.build(:scanned_resource, title: [])
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
      resource = FactoryBot.create_for_repository(:scanned_resource, title: 'Title', imported_metadata: [{ applicant: 'Test' }], source_metadata_identifier: nil)
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
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
    end

    it "can append files as FileSets", run_real_derivatives: true do
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: false)
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)

      expect(members.to_a.length).to eq 1
      expect(members.first).to be_kind_of FileSet
      expect(output.thumbnail_id).to eq [members.first.id]

      file_metadata_nodes = members.first.file_metadata
      expect(file_metadata_nodes.to_a.length).to eq 2
      expect(file_metadata_nodes.first).to be_kind_of FileMetadata
      expect(file_metadata_nodes.first.created_at).not_to be nil
      expect(file_metadata_nodes.first.updated_at).not_to be nil

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
      expect(derivative_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config['derivative_path']).to_s)

      expect(query_service.find_all.to_a.map(&:class)).to contain ScannedResource, FileSet
    end

    it "cleans up derivatives", run_real_derivatives: true do
      allow(CharacterizationJob).to receive(:set).and_call_original
      allow(CreateDerivativesJob).to receive(:set).and_call_original

      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: true)
      change_set.files = [file]
      change_set_persister.queue = 'low'
      output = change_set_persister.save(change_set: change_set)
      file_set = query_service.find_members(resource: output).first
      expect(file_set.file_metadata.select(&:derivative?)).not_to be_empty
      expect(CharacterizationJob).to have_received(:set).with(queue: 'low')
      expect(CreateDerivativesJob).to have_received(:set).with(queue: 'low')

      updated_change_set = change_set_class.new(output)
      change_set_persister.delete(change_set: updated_change_set)

      query_service.find_members(resource: output).first
      derivative = file_set.file_metadata.select(&:derivative?).first
      expect { query_service.find_by(id: derivative.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "updating files" do
    let(:file1) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:file2) { fixture_file_upload('files/holding_locations.json', 'application/json') }
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
    end

    before do
      now = Time.current
      allow(Time).to receive(:current).and_return(now, now + 1, now + 2)
    end

    it "can append files as FileSets", run_real_derivatives: true do
      # upload a file
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: false)
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
      expect(updated_file_node.updated_at).to be > updated_file_node.created_at
    end

    context 'with a messaging service for scanned resources' do
      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end
      let(:resource) { FactoryBot.build(:scanned_resource) }
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      let(:change_set) { ScannedResourceChangeSet.new(resource, characterize: false) }

      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
        change_set.files = [file1]
      end

      it 'publishes messages for updated file sets', run_real_derivatives: false, rabbit_stubbed: true do
        change_set.member_of_collection_ids = [collection.id]
        change_set.sync
        output = change_set_persister.save(change_set: change_set)
        file_set = query_service.find_members(resource: output).first

        change_set = FileSetChangeSet.new(file_set)
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{output.id}/manifest",
          "collection_slugs" => ['test']
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end

      it 'publishes messages for updates and creating file sets', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        file_set = query_service.find_members(resource: output).first

        fs_change_set = FileSetChangeSet.new(file_set)
        fs_output = change_set_persister.save(change_set: fs_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{output.id}/manifest",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)

        fs_expected_result = {
          "id" => fs_output.id.to_s,
          "event" => "CREATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{output.id}/manifest",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(fs_expected_result.to_json)
      end

      it 'publishes messages for deletion', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        updated_change_set = ScannedResourceChangeSet.new(output)
        change_set_persister.delete(change_set: updated_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "DELETED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{output.id}/manifest"
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end
    end

    context 'with a messaging service for Ephemera Folder' do
      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end
      let(:resource) { FactoryBot.build(:ephemera_folder) }
      let(:change_set) { EphemeraFolderChangeSet.new(resource, characterize: false) }

      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
        change_set.files = [file1]
      end

      it 'publishes messages for updated file sets', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [output.id])
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

        file_set = query_service.find_members(resource: output).first

        change_set = FileSetChangeSet.new(file_set)
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end

      it 'publishes messages for updates and creating file sets', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [output.id])
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

        file_set = query_service.find_members(resource: output).first

        fs_change_set = FileSetChangeSet.new(file_set)
        fs_output = change_set_persister.save(change_set: fs_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)

        fs_expected_result = {
          "id" => fs_output.id.to_s,
          "event" => "CREATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(fs_expected_result.to_json)
      end

      it 'publishes messages for deletion', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        updated_change_set = EphemeraFolderChangeSet.new(output)
        change_set_persister.delete(change_set: updated_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "DELETED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest"
        }

        expect(rabbit_connection).to have_received(:publish).once.with(expected_result.to_json)
      end
    end

    context 'with an Ephemera Box' do
      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end
      let(:resource) { FactoryBot.create_for_repository(:ephemera_box) }
      let(:change_set) { EphemeraBoxChangeSet.new(resource, characterize: false) }

      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
      end

      it 'publishes messages for updated properties', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [output.id])

        change_set = EphemeraBoxChangeSet.new(output, tracking_number: '23456')
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_boxes/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end

      it 'publishes messages for deletion', run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        updated_change_set = EphemeraBoxChangeSet.new(output)
        change_set_persister.delete(change_set: updated_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "DELETED",
          "manifest_url" => "http://www.example.com/concern/ephemera_boxes/#{output.id}/manifest"
        }

        expect(rabbit_connection).to have_received(:publish).once.with(expected_result.to_json)
      end
    end
  end

  describe "collection interactions" do
    context "when a collection is deleted" do
      it "cleans up associations from all its members" do
        collection = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id)
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
        child = FactoryBot.create_for_repository(:scanned_resource)
        parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)
        change_set = ScannedResourceChangeSet.new(child)

        change_set_persister.delete(change_set: change_set)
        reloaded = query_service.find_by(id: parent.id)

        expect(reloaded.member_ids).to eq []
      end

      it "cleans up structure nodes" do
        child1 = FactoryBot.create_for_repository(:scanned_resource, title: ['child1'])
        child2 = FactoryBot.create_for_repository(:scanned_resource, title: ['child2'])
        structure = {
          "label": "Top!",
          "nodes": [
            { "label": "Chapter 1",
              "nodes": [
                { "proxy": child1.id }
              ] },
            { "label": "Chapter 2",
              "nodes": [
                { "proxy": child2.id }
              ] }
          ]
        }
        parent = FactoryBot.create_for_repository(:scanned_resource, logical_structure: [structure], member_ids: [child1.id, child2.id])
        change_set = ScannedResourceChangeSet.new(child1)

        change_set_persister.delete(change_set: change_set)
        reloaded = query_service.find_by(id: parent.id)

        chapter1_node = reloaded.logical_structure.first.nodes.first
        expect(chapter1_node.nodes).to be_empty
      end
    end
  end

  describe "deleting multi-volume scanned resources" do
    it "deletes children" do
      child = FactoryBot.create_for_repository(:scanned_resource)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)
      change_set = ScannedResourceChangeSet.new(parent)
      change_set_persister.save(change_set: change_set)

      change_set_persister.delete(change_set: change_set)

      expect { query_service.find_by(id: child.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    end
  end

  describe "deleting vocabularies" do
    it "deletes EphemeraFields which reference it" do
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      ephemera_field = FactoryBot.create_for_repository(:ephemera_field, member_of_vocabulary_id: vocabulary.id)
      change_set = EphemeraVocabularyChangeSet.new(vocabulary)

      change_set_persister.delete(change_set: change_set)
      expect { query_service.find_by(id: ephemera_field.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "setting visibility" do
    context "when setting to public" do
      it "adds the public read_group" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: 'open')
        change_set.sync

        expect(change_set.model.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
    end
    context "when setting to princeton only" do
      it "adds the authenticated read_group" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        change_set.sync

        expect(change_set.model.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end
    end
    context "when setting to private" do
      it "removes all read groups" do
        resource = FactoryBot.build(:scanned_resource, read_groups: ['public'])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
        change_set.sync

        expect(change_set.model.read_groups).to eq []
      end
    end

    context "with existing member resources and file sets" do
      let(:resource1) { FactoryBot.create_for_repository(:file_set) }
      let(:resource2) { FactoryBot.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the access control policies, but not to FileSets" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [])
        resource.member_ids = [resource1.id, resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
        change_set.sync

        updated = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: updated)
        expect(members.first.read_groups).to eq resource1.read_groups
        expect(members.to_a.last.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
    end
  end

  describe "setting state" do
    context "with member resources and file sets" do
      let(:resource2) { FactoryBot.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the workflow state" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [], state: 'pending')
        resource.member_ids = [resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(state: 'pending')
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)
        expect(members.first.state).to eq ['pending']
      end
    end
    context "with boxes and folders" do
      let(:change_set_class) { EphemeraBoxChangeSet }
      it "doesn't overwrite the folder workflow state" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id)

        change_set = change_set_class.new(box)
        change_set.validate(state: 'ready_to_ship')
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)
        expect(members.first.state).not_to eq ['ready_to_ship']
      end
      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
      end

      it "re-indexes the child folders when marked all_in_production", rabbit_stubbed: true do
        allow(rabbit_connection).to receive(:publish)
        solr = Blacklight.default_index.connection
        folder = FactoryBot.create_for_repository(:ephemera_folder, state: "needs_qa")
        box = FactoryBot.create_for_repository(:ephemera_box, state: 'received', member_ids: folder.id)

        change_set = change_set_class.new(box)
        change_set.validate(state: 'all_in_production')
        change_set.sync

        change_set_persister.save(change_set: change_set)
        doc = solr.get("select", params: { q: "id:#{folder.id}", fl: "read_access_group_ssim", rows: 1 })["response"]["docs"].first
        expect(doc["read_access_group_ssim"]).to eq ["public"]
        expected_result = {
          "id" => folder.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{folder.id}/manifest",
          "collection_slugs" => []
        }
        expect(rabbit_connection).to have_received(:publish).once.with(expected_result.to_json)
      end
    end
  end

  describe "appending" do
    it "appends a child via #append_id" do
      parent = FactoryBot.create_for_repository(:scanned_resource)
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(append_id: parent.id.to_s)
      change_set.sync

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)
      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
    end
  end

  context "setting visibility from remote metadata" do
    context "when date is before 1924" do
      it "sets it to public domain and open" do
        stub_bibdata(bib_id: "4609321")
        resource = FactoryBot.build(:pending_private_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.prepopulate!
        change_set.validate(source_metadata_identifier: '4609321', set_visibility_by_date: "1")
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ['public']
        expect(reloaded.rights_statement).to eq [RDF::URI.new("http://rightsstatements.org/vocab/NKC/1.0/")]
      end
    end
    context "when date is after 1924" do
      it "sets it to in copyright and private" do
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.build(:pending_private_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.prepopulate!
        change_set.validate(source_metadata_identifier: '123456', set_visibility_by_date: "1")
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
        expect(reloaded.read_groups).to eq []
        expect(reloaded.rights_statement).to eq [RDF::URI.new("http://rightsstatements.org/vocab/InC/1.0/")]
      end
    end
    context "when given a bad date" do
      it "does nothing" do
        stub_bibdata(bib_id: "123456789")
        resource = FactoryBot.build(:pending_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.prepopulate!
        change_set.validate(source_metadata_identifier: '123456789', set_visibility_by_date: "1")
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ['public']
        expect(reloaded.rights_statement).to eq [RDF::URI.new("http://rightsstatements.org/vocab/NKC/1.0/")]
      end
    end
    context "when not told to set visibility by date" do
      it "does nothing" do
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.build(:pending_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.prepopulate!
        change_set.validate(source_metadata_identifier: '123456')
        change_set.sync

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ['public']
        expect(reloaded.rights_statement).to eq [RDF::URI.new("http://rightsstatements.org/vocab/NKC/1.0/")]
      end
    end
  end
end
