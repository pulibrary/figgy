# coding: utf-8
# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ChangeSetPersister do
  with_queue_adapter :inline
  subject(:change_set_persister) do
    described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
  end

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_class) { ScannedResourceChangeSet }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:disk_preservation_path) { Pathname.new(Figgy.config["disk_preservation_path"]) }

  it_behaves_like "a Valkyrie::ChangeSetPersister"

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
  end

  context "when a scanned resource is completed" do
    before do
      stub_catalog(bib_id: "123456")
    end

    it "mints an ARK" do
      resource = FactoryBot.create(:scanned_resource, title: [], source_metadata_identifier: "123456", state: "final_review")
      change_set = change_set_class.new(resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)
      expect(output.identifier.first).to eq "ark:/#{shoulder}#{blade}"
    end

    it "mints an authorization token" do
      resource = FactoryBot.create(:playlist, title: ["test playlist"], state: "draft")
      change_set = PlaylistChangeSet.new(resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)

      expect(output.auth_token).not_to be nil
      auth_token = AuthToken.find_by(token: output.auth_token)
      expect(auth_token).not_to be nil
      expect(auth_token.label).to eq "Anonymous Token"
      expect(auth_token.group).to eq ["anonymous"]
    end
  end

  context "when a client requests that an auth. token be renewed" do
    let(:resource) { FactoryBot.create(:playlist) }
    let(:change_set_class) { PlaylistChangeSet }
    let(:change_set) { change_set_class.new(resource) }
    let(:persisted) do
      change_set.validate(state: "complete")
      change_set_persister.save(change_set: change_set)
    end

    before do
      persisted
    end

    it "replaces an existing auth. token" do
      token = persisted.auth_token
      auth_token = AuthToken.find_by(token: token)
      expect(auth_token).not_to be nil

      cs = PlaylistChangeSet.new(persisted)
      cs.validate(mint_auth_token: true)

      updated = change_set_persister.save(change_set: cs)

      expect(updated.auth_token).not_to be nil
      expect(updated.auth_token).not_to eq token

      expect(AuthToken.find_by(token: token)).to be nil
    end
  end

  context "when a playlist is taken down" do
    before do
      stub_catalog(bib_id: "123456")
    end

    context "with an authorization token" do
      let(:resource) { FactoryBot.create(:playlist) }
      let(:change_set_class) { PlaylistChangeSet }
      let(:change_set) { change_set_class.new(resource) }
      let(:persisted) do
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)
      end
      before do
        persisted
      end
      it "clears the attribute on the model but preserves the token" do
        persisted_auth_token = persisted.auth_token
        takedown_change_set = change_set_class.new(persisted)
        takedown_change_set.validate(state: "draft")
        change_set_persister.save(change_set: takedown_change_set)

        auth_token = AuthToken.find_by(token: persisted_auth_token)

        expect(auth_token).not_to be nil
        expect(auth_token.resource_id).to eq persisted.id.to_s
      end
    end
  end

  context "when a simple resource is completed" do
    let(:change_set_class) { SimpleChangeSet }
    before do
      stub_catalog(bib_id: "123456")
    end

    it "mints an ARK" do
      resource = FactoryBot.create(:draft_simple_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)
      expect(output.identifier.first).to eq "ark:/#{shoulder}#{blade}"
    end

    context "after having been taken down" do
      let(:resource) { FactoryBot.create(:playlist) }
      let(:change_set_class) { PlaylistChangeSet }
      let(:change_set) { change_set_class.new(resource) }
      let(:persisted) do
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)
      end
      let(:take_down) do
        takedown_change_set = change_set_class.new(persisted)
        takedown_change_set.validate(state: "draft")
        change_set_persister.save(change_set: takedown_change_set)
      end
      let(:completed) do
        complete_change_set = change_set_class.new(take_down)
        complete_change_set.validate(state: "complete")
        change_set_persister.save(change_set: complete_change_set)
      end
      it "uses the same authorization token" do
        expect(persisted.auth_token).not_to be nil
        auth_token = AuthToken.find_by(token: persisted.auth_token)
        expect(auth_token).not_to be nil

        completed_auth_token = completed.auth_token
        expect(completed_auth_token).not_to be nil
        expect(completed_auth_token).to eq auth_token.token
        expect(AuthToken.find_by(resource_id: completed.id.to_s)).to eq(auth_token.reload)
      end
    end
  end

  describe "running ocr after changing ocr_language" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
    end

    it "can append files as FileSets", run_real_derivatives: true do
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: false)
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)
      expect(members.first.hocr_content).not_to be_present

      change_set = change_set_class.new(output)
      change_set.validate(ocr_language: "eng")

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)
      expect(members.first.hocr_content).to be_present
    end
  end

  describe "ocr functionality" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
    end
    it "doesn't run OCR if blank" do
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: false)
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)
      expect(members.first.hocr_content).not_to be_present

      change_set = change_set_class.new(output)
      change_set.validate(ocr_language: "")

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)
      expect(members.first.hocr_content).not_to be_present
    end
  end

  describe "uploading files" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
    end

    context "when uploading files from the cloud", run_real_characterization: false, run_real_derivatives: false do
      let(:file) do
        PendingUpload.new(
          id: SecureRandom.uuid,
          upload_id: "test-upload-id",
          upload_file_id: "https://www.example.com/resource1/1.tif"
        )
      end
      let(:binary_file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:bytestream) { instance_double(ActiveStorage::Blob) }
      let(:upload_file) { double }
      let(:upload_file_id) { "https://www.example.com/resource1/1.tif" }
      let(:pending_upload) { PendingUpload.new(upload_file_id: upload_file_id) }

      before do
        allow(upload_file).to receive(:purge_bytestream)
        allow(upload_file).to receive(:name).and_return("example.tif")
        allow(upload_file).to receive(:id).and_return(upload_file_id)
        allow(BrowseEverything::UploadFile).to receive(:find).and_return([upload_file])
      end

      it "persists the files" do
        allow(upload_file).to receive(:download).and_return(File.read(binary_file))
        resource = FactoryBot.build(:scanned_resource, pending_uploads: [pending_upload])
        change_set = change_set_class.new(resource, characterize: false, ocr_language: ["eng"])
        change_set.files = [file]

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)

        expect(members.to_a.length).to eq 1
      end

      context "when the download fails" do
        before do
          allow(upload_file).to receive(:download).and_raise(StandardError)
          allow(Honeybadger).to receive(:notify)
        end

        it "does not append that file", run_real_derivatives: true do
          resource = FactoryBot.build(:scanned_resource)
          change_set = change_set_class.new(resource, characterize: false, ocr_language: ["eng"])
          change_set.files = [file]

          output = change_set_persister.save(change_set: change_set)
          members = query_service.find_members(resource: output)

          expect(Honeybadger).to have_received(:notify)
          expect(members.to_a.length).to eq 0
        end
      end
    end

    it "runs characterization for all files when added in sequence with the same persister", run_real_derivatives: true do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(files: [file])
      output = change_set_persister.save(change_set: change_set)

      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        change_set = change_set_class.new(output)
        change_set.validate(ocr_language: "eng")
        output = buffered_change_set_persister.save(change_set: change_set)
      end

      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        change_set = change_set_class.new(output)
        change_set.validate(files: [file])
        output = buffered_change_set_persister.save(change_set: change_set)
      end
      members = Wayfinder.for(output).members
      expect(members[1].original_file.height).to be_present
    end

    context "when characterization/derivatives don't run" do
      with_queue_adapter :test
      it "marks files as in process before they're characterized" do
        resource = FactoryBot.build(:scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.files = [file]

        output = change_set_persister.save(change_set: change_set)
        members = Wayfinder.for(output).members

        expect(members.first.processing_status).to eq "in process"
      end
    end
    it "can append files as FileSets", run_real_derivatives: true do
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: false, ocr_language: ["eng"])
      change_set.files = [file]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)

      expect(members.to_a.length).to eq 1
      expect(members.first).to be_kind_of FileSet
      expect(members.first.title).to eq ["example.tif"]
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
      expect(derivative_file.io.path).to start_with(Rails.root.join("tmp", Figgy.config["pyramidal_derivative_path"]).to_s)

      pyramidal_derivative = file_metadata_nodes.find { |x| x.use == [Valkyrie::Vocab::PCDMUse.ServiceFile] && x.mime_type == ["image/tiff"] }
      expect(pyramidal_derivative).not_to be_blank

      expect(query_service.find_all.to_a.map(&:class)).to contain_exactly ScannedResource, FileSet

      expect(members.first.hocr_content).not_to be_blank
      expect(members.first.processing_status).to eq "processed"
    end

    context "with an xml file" do
      let(:file) { fixture_file_upload("files/geo_metadata/fgdc.xml", "text/xml") }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end

      it "appends file as a FileSet but does not set the thumbnail_id" do
        resource = FactoryBot.build(:scanned_resource)
        change_set = change_set_class.new(resource, characterize: false)
        change_set.files = [file]

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)

        expect(members.to_a.length).to eq 1
        expect(members.first).to be_kind_of FileSet
        expect(output.thumbnail_id).to be_nil
      end
    end

    context "with an audiovisual media file" do
      with_queue_adapter :inline
      let(:change_set_class) { RecordingChangeSet }
      let(:file) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "audio/x-wav") }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
      end
      let(:tracks) { double }
      let(:audio_track_attributes) { double }

      before do
        allow(audio_track_attributes).to receive(:encoded_date).and_return Time.zone.parse("UTC 2009-03-30 19:49:13")
        allow(audio_track_attributes).to receive(:producer).and_return("PULibrary")
        allow(audio_track_attributes).to receive(:originalsourceform).and_return("cassette")
        allow(audio_track_attributes).to receive(:duration).and_return(23_123)
        allow(audio_track_attributes).to receive(:count).and_return 1
        allow(audio_track_attributes).to receive(:filesize).and_return 100

        allow(tracks).to receive(:track_types).and_return(["audio"])
        allow(tracks).to receive(:audio).and_return(audio_track_attributes)
        allow(tracks).to receive(:video).and_return(nil)
        allow(tracks).to receive(:audio?).and_return(true)
        allow(tracks).to receive(:video?).and_return(false)
        allow(MediaInfo).to receive(:from).and_return(tracks)
      end

      it "appends file as a FileSet and extracts the technical metadata" do
        resource = FactoryBot.build(:recording)
        change_set = change_set_class.new(resource, characterize: true)
        change_set.files = [file]

        attributes = { id: SecureRandom.uuid, use: [Valkyrie::Vocab::PCDMUse.OriginalFile, Valkyrie::Vocab::PCDMUse.PreservationFile] }
        file_metadata_node = FileMetadata.for(file: file).new(attributes)
        allow(FileMetadata).to receive(:for).and_return(file_metadata_node)

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)

        expect(members.to_a.length).to eq 1
        expect(members.first).to be_kind_of FileSet

        expect(members.first.date_of_digitization).not_to be_empty
        expect(members.first.date_of_digitization.first).to be_a DateTime
        expect(members.first.date_of_digitization.first).to eq DateTime.iso8601("2009-03-30T19:49:13.000Z").utc
        expect(members.first.producer).to eq ["PULibrary"]
        expect(members.first.source_media_type).to eq ["cassette"]
        expect(members.first.duration).to eq ["23.123"]
      end
      it "works when attached to a ScannedResource", run_real_characterization: true, run_real_derivatives: true do
        file = fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "text/plain")
        resource = FactoryBot.build(:scanned_resource)
        change_set = ScannedResourceChangeSet.new(resource, characterize: true)
        change_set.files = [file]

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)

        expect(members.first.original_file.duration).not_to be_blank
        expect(members.first.original_file.mime_type).to eq ["audio/x-wav"]
        expect(members.first.original_file.checksum).not_to be_blank
      end
    end

    context "with numismatics coin files" do
      let(:file1) { fixture_file_upload("numismatics/coin-images/1O.tif", "image/tiff") }
      let(:file2) { fixture_file_upload("numismatics/coin-images/1R.jpg", "image/jpeg") }
      let(:file3) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
      let(:change_set_class) { Numismatics::CoinChangeSet }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end

      it "appends files as a FileSet with an Obverse or Reverse title" do
        resource = FactoryBot.build(:coin)
        change_set = change_set_class.new(resource, characterize: false)
        change_set.files = [file1, file2, file3]

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)

        expect(members.to_a.length).to eq 3
        expect(members.first).to be_kind_of FileSet
        expect(members.first.title).to eq ["Obverse"]
        expect(members[1].title).to eq ["Reverse"]
        expect(members[2].title).to eq ["abstract.tiff"]
      end
    end
  end

  describe "updating files" do
    let(:file1) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:file2) { fixture_file_upload("files/holding_locations.json", "application/json") }
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
    end

    context "with a messaging service for scanned resources" do
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

      it "publishes messages for updated file sets", run_real_derivatives: false, rabbit_stubbed: true do
        change_set.member_of_collection_ids = [collection.id]
        output = change_set_persister.save(change_set: change_set)
        file_set = query_service.find_members(resource: output).first

        change_set = FileSetChangeSet.new(file_set)
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "MEMBER_UPDATED",
          "manifest_url" => "http://www.example.com/concern/scanned_resources/#{output.id}/manifest",
          "collection_slugs" => ["test"]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)

        expected_result_fs = {
          "id" => file_set.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result_fs.to_json)
      end

      it "publishes messages for updates and creating file sets", run_real_derivatives: false, rabbit_stubbed: true do
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
          "manifest_url" => "",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(fs_expected_result.to_json)
      end

      it "publishes messages for deletion", run_real_derivatives: false, rabbit_stubbed: true do
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

    context "with a messaging service for Ephemera Folder" do
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

      it "publishes messages for updated file sets", run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [output.id])
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

        file_set = query_service.find_members(resource: output).first

        change_set = FileSetChangeSet.new(file_set)
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "MEMBER_UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end

      it "publishes messages for updates and creating file sets", run_real_derivatives: false, rabbit_stubbed: true do
        change_set.member_of_collection_ids = [FactoryBot.create_for_repository(:collection, slug: "testing").id]
        output = change_set_persister.save(change_set: change_set)
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [output.id])
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

        file_set = query_service.find_members(resource: output).first

        fs_change_set = FileSetChangeSet.new(file_set)
        fs_output = change_set_persister.save(change_set: fs_change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "MEMBER_UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug, "testing"]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)

        fs_expected_result = {
          "id" => fs_output.id.to_s,
          "event" => "CREATED",
          "manifest_url" => "",
          "collection_slugs" => []
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(fs_expected_result.to_json)
      end

      it "publishes messages for deletion", run_real_derivatives: false, rabbit_stubbed: true do
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

    context "with an Ephemera Box" do
      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      let(:change_set_persister) do
        described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: false)
      end
      let(:resource) { FactoryBot.create_for_repository(:ephemera_box) }
      let(:change_set) { EphemeraBoxChangeSet.new(resource, characterize: false) }

      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
      end

      it "publishes messages for updated properties", run_real_derivatives: false, rabbit_stubbed: true do
        output = change_set_persister.save(change_set: change_set)
        ephemera_project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [output.id])

        change_set = EphemeraBoxChangeSet.new(output, tracking_number: "23456")
        change_set_persister.save(change_set: change_set)

        expected_result = {
          "id" => output.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_boxes/#{output.id}/manifest",
          "collection_slugs" => [ephemera_project.decorate.slug]
        }

        expect(rabbit_connection).to have_received(:publish).at_least(:once).with(expected_result.to_json)
      end

      it "publishes messages for deletion", run_real_derivatives: false, rabbit_stubbed: true do
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

  describe "deleting a resource" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:change_set_persister) do
      described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter, characterize: true)
    end
    it "cleans up derivatives and original files", run_real_derivatives: true do
      allow(CharacterizationJob).to receive(:set).and_call_original
      allow(CreateDerivativesJob).to receive(:set).and_call_original

      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource, characterize: true, ocr_language: ["eng"])
      change_set.files = [file]
      change_set_persister.queue = "low"
      output = change_set_persister.save(change_set: change_set)
      file_set = query_service.find_members(resource: output).first
      expect(file_set.file_metadata.select(&:derivative?)).not_to be_empty
      expect(file_set.original_file).to be_a FileMetadata
      expect(CharacterizationJob).to have_received(:set).with(queue: "low")
      expect(CreateDerivativesJob).to have_received(:set).with(queue: "low")

      updated_change_set = change_set_class.new(output)
      change_set_persister.delete(change_set: updated_change_set)

      query_service.find_members(resource: output).first
      derivative = file_set.file_metadata.find(&:derivative?)
      derivative_path = derivative.file_identifiers.first.to_s.gsub("disk://", "")
      expect(File.exist?(derivative_path)).to be false
      original = file_set.original_file
      original_path = original.file_identifiers.first.to_s.gsub("disk://", "")
      expect(File.exist?(original_path)).to be false
    end
    it "destroys any active authorization tokens" do
      resource = FactoryBot.create(:playlist)
      change_set = PlaylistChangeSet.new(resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)

      auth_token = AuthToken.find_by(token: output.auth_token)
      expect(auth_token).not_to be nil
      deleted_change_set = PlaylistChangeSet.new(output)
      change_set_persister.delete(change_set: deleted_change_set)

      expect(AuthToken.find_by(token: auth_token.token)).to be nil
    end
    context "when the Playlist is and completed and taken down before deletion" do
      let(:resource) { FactoryBot.create(:playlist) }
      let(:change_set_class) { PlaylistChangeSet }
      let(:change_set) { change_set_class.new(resource) }
      let(:completed) do
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)
      end
      let(:taken_down) do
        takedown_cs = change_set_class.new(completed)
        takedown_cs.validate(state: "takedown")
        change_set_persister.save(change_set: takedown_cs)
      end

      it "destroys any inactive authorization tokens" do
        auth_token = AuthToken.find_by(token: completed.auth_token)
        expect(auth_token).not_to be nil

        auth_token = AuthToken.find_by(resource_id: taken_down.id.to_s)
        expect(auth_token).not_to be nil

        deleted_change_set = change_set_class.new(taken_down)
        change_set_persister.delete(change_set: deleted_change_set)

        expect(AuthToken.find_by(token: completed.auth_token)).to be nil
        expect(AuthToken.find_by(resource_id: taken_down.id.to_s)).to be nil
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
        child1 = FactoryBot.create_for_repository(:scanned_resource, title: ["child1"])
        child2 = FactoryBot.create_for_repository(:scanned_resource, title: ["child2"])
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
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

    it "deletes children" do
      child = FactoryBot.create_for_repository(:scanned_resource)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)
      change_set = ScannedResourceChangeSet.new(parent)
      change_set_persister.save(change_set: change_set)

      change_set_persister.delete(change_set: change_set)

      expect { query_service.find_by(id: child.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
    end

    it "deletes the thumbnail_id" do
      child = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id)
      change_set = ScannedResourceChangeSet.new(parent)
      change_set.validate(thumbnail_id: child.decorate.file_sets.first.id)
      persisted_parent = change_set_persister.save(change_set: change_set)
      expect(persisted_parent.thumbnail_id).to eq [child.decorate.file_sets.first.id]

      child_change_set = ScannedResourceChangeSet.new(child)
      change_set_persister.delete(change_set: child_change_set)

      reloaded = query_service.find_by(id: parent.id)
      expect(reloaded).to be_a ScannedResource
      expect(reloaded.thumbnail_id).to be_empty
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
        change_set.validate(visibility: "open")
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
        resource = FactoryBot.build(:scanned_resource, read_groups: ["public"])
        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
        change_set.sync

        expect(change_set.model.read_groups).to eq []
      end
    end

    context "with existing member resources and file sets" do
      let(:resource1) { FactoryBot.create_for_repository(:file_set) }
      let(:resource2) { FactoryBot.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the access control policies to resources and FileSets" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [])
        resource.member_ids = [resource1.id, resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        updated = change_set_persister.save(change_set: change_set)

        members = query_service.find_members(resource: updated)
        expect(members.first.read_groups).to eq updated.read_groups
        resource_member = members.to_a.last
        expect(resource_member.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(resource_member.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
      it "doesn't propagate if there's been no change" do
        child = FactoryBot.create_for_repository(:scanned_resource, read_groups: [])
        resource = FactoryBot.build(:scanned_resource, read_groups: [])
        resource.member_ids = [child.id]
        change_set = ChangeSet.for(resource)
        resource = change_set_persister.save(change_set: change_set)
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        child = adapter.query_service.find_by(id: child.id)

        change_set = change_set_class.new(resource)
        updated = change_set_persister.save(change_set: change_set)

        members = query_service.find_members(resource: updated)
        expect(members.first.updated_at).to eq child.updated_at
      end
    end
  end

  describe "setting state" do
    context "with member resources and file sets" do
      let(:resource2) { FactoryBot.create_for_repository(:complete_private_scanned_resource) }
      it "propagates the workflow state" do
        resource = FactoryBot.build(:scanned_resource, read_groups: [], state: "pending")
        resource.member_ids = [resource2.id]
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
        resource = adapter.persister.save(resource: resource)

        change_set = change_set_class.new(resource)
        change_set.validate(state: "pending")

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)
        expect(members.first.state).to eq ["pending"]
      end
    end

    context "with archival media collection and media resource members" do
      let(:amc) { FactoryBot.create_for_repository(:collection, change_set: "archival_media_collection", state: "draft") }
      it "does not propagate the workflow state" do
        FactoryBot.create_for_repository(:recording, state: "draft", member_of_collection_ids: amc.id)

        members = Wayfinder.for(amc).members
        expect(members.first.state).to eq ["draft"]

        change_set = ChangeSet.for(amc)
        change_set.validate(state: "complete")
        output = change_set_persister.save(change_set: change_set)
        expect(output.identifier.first).to eq "ark:/#{shoulder}#{blade}"

        members = Wayfinder.for(output).members
        expect(members.first.state).to eq ["draft"]
        expect(members.first.identifier).to be nil
      end
    end

    context "with a collection" do
      let(:collection) { FactoryBot.create_for_repository(:collection) }
      it "does not propagate visibility" do
        FactoryBot.create_for_repository(:pending_private_scanned_resource, member_of_collection_ids: collection.id)

        change_set = ChangeSet.for(collection)
        change_set.validate(title: "new title")
        output = change_set_persister.save(change_set: change_set)

        members = Wayfinder.for(output).members
        expect(members.first.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
      end
      it "doesn't propagate read groups or state, having neither of these fields" do
        FactoryBot.create_for_repository(:pending_private_scanned_resource, member_of_collection_ids: collection.id)

        change_set = ChangeSet.for(collection)
        change_set.validate(title: "new title", visibility: nil)
        output = change_set_persister.save(change_set: change_set)

        members = Wayfinder.for(output).members
        expect(members.first.state).to eq ["pending"]
        expect(members.first.read_groups).to eq []
      end
    end

    context "with boxes and folders" do
      let(:change_set_class) { EphemeraBoxChangeSet }
      it "doesn't overwrite the folder workflow state" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id)

        change_set = change_set_class.new(box)
        change_set.validate(state: "ready_to_ship")

        output = change_set_persister.save(change_set: change_set)
        members = query_service.find_members(resource: output)
        expect(members.first.state).not_to eq ["ready_to_ship"]
      end

      let(:rabbit_connection) { instance_double(MessagingClient, publish: true) }
      before do
        allow(Figgy).to receive(:messaging_client).and_return(rabbit_connection)
      end

      it "re-indexes the child folders when marked all_in_production", rabbit_stubbed: true do
        allow(rabbit_connection).to receive(:publish)
        solr = Blacklight.default_index.connection
        folder = FactoryBot.create_for_repository(:ephemera_folder, state: "needs_qa")
        box = FactoryBot.create_for_repository(:ephemera_box, state: "received", member_ids: folder.id)

        change_set = change_set_class.new(box)
        change_set.validate(state: "all_in_production")

        change_set_persister.save(change_set: change_set)
        doc = solr.get("select", params: { q: "id:#{folder.id}", fl: "read_access_group_ssim", rows: 1 })["response"]["docs"].first
        expect(doc["read_access_group_ssim"]).to eq ["public"]
        expected_result = {
          "id" => folder.id.to_s,
          "event" => "UPDATED",
          "manifest_url" => "http://www.example.com/concern/ephemera_folders/#{folder.id}/manifest",
          "collection_slugs" => []
        }
        # the object currently reindexes twice; once from the behavior tested here, and once because we're propagating state
        # to the child and saving it through the change set persister pipeline so it can get an ark, emit this message, etc.
        # this reindexing behavior should be cleaned up as part of 1405
        expect(rabbit_connection).to have_received(:publish).twice.with(expected_result.to_json)
      end
    end
  end

  describe "appending" do
    it "appends a child via #append_id" do
      parent = FactoryBot.create_for_repository(:scanned_resource)
      resource = FactoryBot.build(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(append_id: parent.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)
      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
      expect(output.cached_parent_id).to eq reloaded.id
    end

    it "will not append to the same parent twice" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: resource.id)
      change_set = change_set_class.new(resource)
      change_set.validate(append_id: parent.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      reloaded = query_service.find_by(id: parent.id)

      expect(reloaded.member_ids).to eq [output.id]
      expect(reloaded.thumbnail_id).to eq [output.id]
      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{parent.id}"]
    end

    it "moves a child from another parent via #append_id" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      old_parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: resource.id)
      new_parent = FactoryBot.create_for_repository(:scanned_resource)

      change_set = change_set_class.new(resource)
      change_set.validate(append_id: new_parent.id.to_s)
      output = change_set_persister.save(change_set: change_set)

      new_reloaded = query_service.find_by(id: new_parent.id)
      old_reloaded = query_service.find_by(id: old_parent.id)

      expect(new_reloaded.member_ids).to eq [output.id]
      expect(new_reloaded.thumbnail_id).to eq [output.id]

      expect(old_reloaded.member_ids).to eq []
      expect(old_reloaded.thumbnail_id).to be_blank

      solr_record = Blacklight.default_index.connection.get("select", params: { qt: "document", q: "id:#{output.id}" })["response"]["docs"][0]
      expect(solr_record["member_of_ssim"]).to eq ["id-#{new_parent.id}"]
    end

    it "will not append a resource as a child of itself" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = change_set_class.new(resource)
      change_set.validate(append_id: resource.id.to_s)

      output = change_set_persister.save(change_set: change_set)
      expect(output.member_ids).to eq []
    end
  end

  context "setting visibility from remote metadata" do
    context "when date is before 1924" do
      it "sets it to public domain and open" do
        stub_catalog(bib_id: "4609321")
        resource = FactoryBot.build(:pending_private_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.validate(source_metadata_identifier: "4609321", set_visibility_by_date: "1")

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ["public"]
        expect(reloaded.rights_statement).to eq [RightsStatements.no_known_copyright]
      end
    end
    context "when date is after 1924" do
      it "sets it to in copyright and private" do
        stub_catalog(bib_id: "123456")
        resource = FactoryBot.build(:pending_private_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.validate(source_metadata_identifier: "123456", set_visibility_by_date: "1")

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
        expect(reloaded.read_groups).to eq []
        expect(reloaded.rights_statement).to eq [RightsStatements.in_copyright]
      end
    end
    context "when given a bad date" do
      it "does nothing" do
        stub_catalog(bib_id: "123456789")
        resource = FactoryBot.build(:pending_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.validate(source_metadata_identifier: "123456789", set_visibility_by_date: "1")

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ["public"]
        expect(reloaded.rights_statement).to eq [RightsStatements.no_known_copyright]
      end
    end
    context "when not told to set visibility by date" do
      it "does nothing" do
        stub_catalog(bib_id: "123456")
        resource = FactoryBot.build(:pending_scanned_resource)
        change_set = change_set_class.new(resource)
        change_set.validate(source_metadata_identifier: "123456")

        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.visibility).to eq [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC]
        expect(reloaded.read_groups).to eq ["public"]
        expect(reloaded.rights_statement).to eq [RightsStatements.no_known_copyright]
      end
    end
  end

  context "when persisting a bag" do
    let(:bag_path) { Rails.root.join("spec", "fixtures", "bags", "valid_bag") }
    let(:resource) { FactoryBot.build(:collection, change_set: "archival_media_collection") }
    let(:change_set_class) { ArchivalMediaCollectionChangeSet }
    let(:change_set) { change_set_class.new(resource, bag_path: bag_path) }

    before do
      stub_findingaid(pulfa_id: "C0652")
      change_set.source_metadata_identifier = "C0652"
    end

    it "persists the file using the bag adapter" do
      output = change_set_persister.save(change_set: change_set)
      expect(output).to be_an Collection
      expect(output.id).not_to be nil
      expect(output.change_set).to eq("archival_media_collection")
    end

    context "with an invalid bag path" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "bags", "invalid_bag") }
      let(:logger) { instance_double(Logger) }
      before do
        allow(logger).to receive(:error)
        allow(Logger).to receive(:new).and_return(logger)
      end

      it "raises an error and does not persist the file" do
        expect { change_set_persister.save(change_set: change_set) }.to raise_error(IngestArchivalMediaBagJob::InvalidBagError, "Bag at #{bag_path} is an invalid bag")
      end
    end
  end

  describe "#save" do
    context "when persisting a bag of audiovisual resources in an existing collection" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
      let(:collection) { FactoryBot.build(:archival_media_collection) }
      let(:change_set) { ArchivalMediaCollectionChangeSet.new(collection, source_metadata_identifier: "C0652", bag_path: bag_path) }

      before do
        stub_findingaid(pulfa_id: "C0652")
        stub_findingaid(pulfa_id: "C0652_c0377")
      end

      it "persists imported metadata for new Recording" do
        output = change_set_persister.save(change_set: change_set)
        reloaded = query_service.find_by(id: output.id)

        results = query_service.find_inverse_references_by(resource: reloaded, property: :member_of_collection_ids)
        members = results.to_a
        expect(members.size).to eq 1

        expect(members.first.title).to include "Interview: ERM / Jose Donoso (A2)"
        expect(members.first.source_metadata_identifier).to include "C0652_c0377"
      end
    end

    context "when persisting a Playlist with ProxyFileSet members" do
      let(:file) { fixture_file_upload("files/audio_file.wav") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
      let(:file_set) { scanned_resource.decorate.decorated_file_sets.first }
      let(:resource) { Playlist.new }
      let(:change_set) do
        cs = PlaylistChangeSet.new(resource)
        cs.validate(title: ["test label"], file_set_ids: [file_set.id])
        cs
      end
      let(:persisted) { change_set_persister.save(change_set: change_set) }
      let(:proxy) do
        query_service.find_by(id: persisted.member_ids.first)
      end
      let(:proxied) do
        query_service.find_by(id: proxy.proxied_file_id)
      end
      before do
        scanned_resource
        persisted
      end
      it "ensures that ProxyFileSet members are updated to use the label from their proxied resources" do
        expect(proxy.label).to eq(proxied.title)
      end

      context "when deleting ProxyFileSet members of a Playlist" do
        before do
          cs = ProxyFileSetChangeSet.new(proxy)
          change_set_persister.delete(change_set: cs)
        end
        it "deletes the proxies and removes them as members of the Playlist" do
          expect { query_service.find_by(id: proxy.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
          reloaded = query_service.find_by(id: persisted.id)
          expect(reloaded.member_ids).to be_empty
        end
      end
    end
  end

  describe "#delete" do
    context "when persisting a Playlist with ProxyFileSet members" do
      let(:file) { fixture_file_upload("files/audio_file.wav") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
      let(:file_set) { scanned_resource.decorate.decorated_file_sets.first }
      let(:resource) { Playlist.new }
      let(:proxy_file_set) do
        proxy_file_set = ProxyFileSet.new
        cs = ProxyFileSetChangeSet.new(proxy_file_set)
        cs.validate(proxied_file_id: file_set.id)
        change_set_persister.save(change_set: cs)
      end
      let(:change_set) do
        cs = PlaylistChangeSet.new(resource)
        cs.validate(title: ["test label"], member_ids: [proxy_file_set.id])
        cs
      end
      let(:persisted) { change_set_persister.save(change_set: change_set) }
      let(:proxy) do
        query_service.find_by(id: persisted.member_ids.first)
      end
      let(:proxied) do
        query_service.find_by(id: proxy.proxied_file_id)
      end
      before do
        scanned_resource
        proxy_file_set
        persisted
      end
      it "deletes ProxyFileSet members when Playlists are deleted, but keeps the FileSets" do
        expect(proxy.persisted?).to be true

        cs = PlaylistChangeSet.new(persisted)
        change_set_persister.delete(change_set: cs)

        expect { query_service.find_by(id: proxy.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.persisted?).to be true
      end
    end
  end

  describe "reindex collection memberes" do
    let(:solr) { Blacklight.default_index.connection }
    let(:collection) { FactoryBot.create_for_repository(:collection, title: "Old Title") }

    it "reindexes members of that collection on title change" do
      resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection.id])

      change_set = ChangeSet.for(collection)
      change_set.validate(title: "New Title")

      change_set_persister.save(change_set: change_set)

      doc = solr.get("select", params: { q: "id:#{resource.id}", fl: "member_of_collection_titles_ssim", rows: 1 })["response"]["docs"].first
      expect(doc["member_of_collection_titles_ssim"]).to eq ["New Title"]
    end

    it "reindexes ephemera folders and boxes if their project is renamed" do
      folder = FactoryBot.create_for_repository(:ephemera_folder)
      box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id], title: "Old Title")

      change_set = ChangeSet.for(project)
      change_set.validate(title: "New Title")

      change_set_persister.save(change_set: change_set)

      folder_doc = solr.get("select", params: { q: "id:#{folder.id}", fl: "ephemera_project_ssim", rows: 1 })["response"]["docs"].first
      expect(folder_doc["ephemera_project_ssim"]).to eq ["New Title"]

      box_doc = solr.get("select", params: { q: "id:#{box.id}", fl: "ephemera_project_ssim", rows: 1 })["response"]["docs"].first
      expect(box_doc["ephemera_project_ssim"]).to eq ["New Title"]
    end
  end

  context "when saving a playlist with file_set_ids" do
    it "creates ProxyFileSets, maintaining order of the files" do
      playlist = Playlist.new
      file_set = FactoryBot.create_for_repository(:file_set)
      file_set2 = FactoryBot.create_for_repository(:file_set)

      change_set = ChangeSet.for(playlist)
      change_set.validate(title: "Test Title", file_set_ids: [file_set2.id.to_s, file_set.id.to_s])
      expect(change_set.file_set_ids).to eq [file_set2.id, file_set.id]

      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)
      proxy_file_set = members.first
      expect(proxy_file_set).to be_a ProxyFileSet
      expect(proxy_file_set.proxied_file_id).to eq file_set2.id
      expect(proxy_file_set.label).to eq file_set2.title
    end
  end

  context "when saving a playlist with duplicate file_set_ids" do
    it "only creates non-duplicates" do
      # Create two file sets
      file_set1 = FactoryBot.create_for_repository(:file_set)
      file_set2 = FactoryBot.create_for_repository(:file_set)
      # Create a Playlist with a pre-existing Proxy pointing to file_set1.
      proxy = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_set1.id)
      playlist = FactoryBot.create_for_repository(:playlist, member_ids: proxy.id)

      # Attempt to create new proxies for both file_set1 and file_set2 using
      # `file_set_ids` on the ChangeSet. file_set1 is already attached through
      # `proxy`.
      change_set = ChangeSet.for(playlist)
      change_set.validate(title: "Test Title", file_set_ids: [file_set1.id.to_s, file_set2.id.to_s])
      output = change_set_persister.save(change_set: change_set)
      members = query_service.find_members(resource: output)

      expect(members.length).to eq 2
      expect(members.map(&:proxied_file_id)).to eq [file_set1.id, file_set2.id]
    end
  end

  describe "preservation" do
    context "when a completed preserved resource is updated outside of the change_set_persister" do
      it "backgrounds any child preserving" do
        allow(Preserver).to receive(:new).and_call_original
        allow(PreserveChildrenJob).to receive(:perform_later).and_call_original
        allow(CleanupFilesJob).to receive(:perform_later)
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
        file_set = Wayfinder.for(resource).members.first
        file_set.read_groups = []
        reloaded_resource = query_service.find_by(id: resource.id)
        resource = change_set_persister.metadata_adapter.persister.save(resource: reloaded_resource)
        change_set_persister.metadata_adapter.persister.save(resource: file_set)
        change_set = ChangeSet.for(resource)

        change_set_persister.save(change_set: change_set)
        expect(PreserveChildrenJob).to have_received(:perform_later).exactly(1).times
        expect(Preserver).to have_received(:new).exactly(4).times
        expect(CleanupFilesJob).not_to have_received(:perform_later)
      end
    end
    context "when completing preserved resource" do
      it "saves to a backup location" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(reloaded_resource)
        change_set.validate(state: "complete")

        output = change_set_persister.save(change_set: change_set)
        expect(Wayfinder.for(output).preservation_object.metadata_node.use).to eq [Valkyrie::Vocab::PCDMUse.PreservedMetadata]
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))).to eq true
        # Verify we can convert from the JSON back to an object.
        attributes = JSON.parse(File.read(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json")))
        attributes = Valkyrie::Persistence::Postgres::ORMConverter::RDFMetadata.new(attributes).result.symbolize_keys
        resource = Valkyrie::Types::Anything[attributes]
        expect(resource).to be_a ScannedResource
        # Verify files exist.
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "#{resource.member_ids.first}.json"))).to eq true
        file_set = Wayfinder.for(output).members.first
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true
        file_set_preservation = Wayfinder.for(file_set).preservation_object
        expect(file_set_preservation.metadata_node.use).to eq [Valkyrie::Vocab::PCDMUse.PreservedMetadata]
        expect(file_set_preservation.binary_nodes.length).to eq 1
        expect(file_set_preservation.binary_nodes[0].use).to eq [Valkyrie::Vocab::PCDMUse.PreservationCopy]
      end
    end
    context "when preserving a parent" do
      with_queue_adapter :test
      it "preserves it inline" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(reloaded_resource)
        change_set.validate(state: "complete")

        output = change_set_persister.save(change_set: change_set)
        expect(Wayfinder.for(output).preservation_object.metadata_node.use).to eq [Valkyrie::Vocab::PCDMUse.PreservedMetadata]
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))).to eq true

        # Files aren't preserved yet, because jobs haven't run.
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "#{resource.member_ids.first}.json"))).to eq false
      end
    end
    context "when a preserved ScannedResource's metadata is updated" do
      it "refreshes the preserved metadata" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set_persister.save(change_set: ChangeSet.for(reloaded_resource))
        file_set = Wayfinder.for(resource).members.first

        modified = File.mtime(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))
        modified_file = File.mtime(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))
        VoyagerUpdateJob.perform_now([resource.id.to_s])
        new_modified = File.mtime(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))
        new_modified_file = File.mtime(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))

        expect(new_modified).not_to eq modified
        expect(modified_file).to eq new_modified_file
      end
    end
    context "when preserving a FileSet with an intermediate/preservation file" do
      it "preserves them" do
        file_set = FactoryBot.create_for_repository(:audio_file_set)
        file = fixture_file_upload("files/example.tif", "image/tiff")
        storage_adapter = Valkyrie::StorageAdapter.find(:disk_via_copy)
        intermediate = storage_adapter.upload(file: file, original_filename: "intermediate", resource: file_set.intermediate_files.first)
        preservation = storage_adapter.upload(file: file, original_filename: "preservation", resource: file_set.preservation_file)
        file_set.intermediate_files.first.file_identifiers = intermediate.id
        file_set.intermediate_files.first.label = "example.tif"
        file_set.preservation_file.file_identifiers = preservation.id
        file_set.preservation_file.label = "example.tif"
        change_set_persister.persister.save(resource: file_set)
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: [file_set.id])

        change_set = ChangeSet.for(resource)
        change_set_persister.save(change_set: change_set)

        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.intermediate_files.first.id}.tif"))).to eq true
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.preservation_file.id}.tif"))).to eq true
      end
    end

    context "when deleting a preserved FileSet" do
      it "Deletes FileSet PreservationObjects, moves file set PreservationObjects into deletion_markers" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(reloaded_resource)
        change_set.validate(state: "complete")

        output = change_set_persister.save(change_set: change_set)
        file_set = Wayfinder.for(output).members.first
        change_set = ChangeSet.for(file_set)
        change_set_persister.delete(change_set: change_set)

        expect(change_set_persister.query_service.find_all_of_model(model: PreservationObject).to_a.length).to eq 1
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))).to eq true
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "#{resource.member_ids.first}.json"))).to eq false
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "data", resource.member_ids.first.to_s, "example-#{file_set.original_file.id}.tif"))).to eq false
        deletion_markers = change_set_persister.query_service.find_all_of_model(model: DeletionMarker)
        expect(deletion_markers.to_a.length).to eq 1
        deletion_marker = deletion_markers.first
        expect(deletion_marker.resource_id).to eq file_set.id
        expect(deletion_marker.resource_title).to eq file_set.title
        expect(deletion_marker.original_filename).to eq file_set.original_file.original_filename
        expect(deletion_marker.deleted_at).to eq deletion_markers.first.created_at
        expect(deletion_marker.preservation_object.preserved_object_id).to eq file_set.id
        expect(deletion_marker.parent_id).to eq resource.id
      end
    end
    context "when deleting preserved resource" do
      it "creates deletion_markers for the resource and all of the related members" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        child_resource = FactoryBot.create_for_repository(:complete_raster_resource)
        resource = FactoryBot.create_for_repository(:pending_scanned_map, title: "title", member_ids: [child_resource.id], files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(reloaded_resource)
        change_set.validate(state: "complete")
        output = change_set_persister.save(change_set: change_set)
        change_set = ChangeSet.for(output)
        change_set_persister.delete(change_set: change_set)

        deletion_markers = change_set_persister.query_service.find_all_of_model(model: DeletionMarker)
        expect(deletion_markers.to_a.length).to eq 3

        # Ensure PreservationObjects are deleted.
        expect(change_set_persister.query_service.find_all_of_model(model: PreservationObject).to_a.length).to eq 0
        expect(File.exist?(disk_preservation_path.join(resource.id.to_s, "#{resource.id}.json"))).to eq false
      end
    end
    context "when reinstating a FileSet deletion_marker" do
      before do
        # Make preservation deletes not actually happen to simulate a versioned
        # file store.
        allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:delete)
        # This is a bug - right now all disk:// storage adapter IDs are going to
        # this adapter, no matter what, so the above never gets called.
        allow(Valkyrie::StorageAdapter.find(:disk)).to receive(:delete)
      end
      it "re-adds the FileSet" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(reloaded_resource)
        change_set.validate(state: "complete")

        output = change_set_persister.save(change_set: change_set)
        file_set = Wayfinder.for(output).members.first
        change_set = ChangeSet.for(file_set)
        change_set_persister.delete(change_set: change_set)

        resource = change_set_persister.query_service.find_by(id: resource.id)
        deletion_marker = change_set_persister.query_service.find_all_of_model(model: DeletionMarker).first
        change_set = ChangeSet.for(resource)
        change_set.deletion_marker_restore_ids = [deletion_marker.id]
        output = change_set_persister.save(change_set: change_set)

        expect(output.member_ids.length).to eq 1
        file_set = change_set_persister.query_service.find_members(resource: output).first
        expect(file_set.file_metadata.length).to eq 2

        # Expect deletion_marker to be gone
        deletion_markers = change_set_persister.query_service.find_all_of_model(model: DeletionMarker)
        expect(deletion_markers.length).to eq 0
      end
    end

    context "when adding FGDC metadata to a preserved object", run_real_derivatives: true, run_real_characterization: true do
      with_queue_adapter :inline

      before do
        allow(GeoserverPublishJob).to receive(:perform_later)
      end

      it "updates the binary content in the preservation store" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        xml = fixture_file_upload("files/geo_metadata/fgdc.xml", "application/xml; schema=fgdc")
        vector_resource = FactoryBot.create_for_repository(:complete_vector_resource, files: [file, xml])
        reloaded_resource = query_service.find_by(id: vector_resource.id)

        output = change_set_persister.save(change_set: ChangeSet.for(reloaded_resource))
        preservation_object = Wayfinder.for(output).preservation_objects.first
        expect(preservation_object).not_to eq nil

        fgdc_file_set = Wayfinder.for(output).geo_metadata_members[0]
        fgdc_preservation = Wayfinder.for(fgdc_file_set).preservation_objects.first
        expect(fgdc_preservation.binary_nodes[0].checksum[0].md5).to eq fgdc_file_set.original_file.checksum[0].md5
      end
    end

    context "when a child is moved around" do
      with_queue_adapter :inline
      it "moves the preservation structure" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        resource = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        parent = FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: resource.id)
        change_set = ChangeSet.for(parent)
        change_set.validate(state: "complete")
        other_parent = FactoryBot.create_for_repository(:complete_scanned_resource)

        # Save in nested structure.
        change_set_persister.save(change_set: change_set)
        # Preserve `other_parent`
        change_set_persister.save(change_set: ChangeSet.for(other_parent))

        reloaded = change_set_persister.query_service.find_by(id: resource.id)

        # Move resource from parent to other_parent
        change_set = ChangeSet.for(reloaded)
        change_set.append_id = other_parent.id
        change_set_persister.save(change_set: change_set)

        cloud_path = disk_preservation_path
        # Ensure it's preserved in its new location
        expect(File.exist?(cloud_path.join(other_parent.id.to_s, "data", reloaded.id.to_s, "#{reloaded.id}.json"))).to eq true
        # Ensure it's removed from its old location
        expect(File.exist?(cloud_path.join(parent.id.to_s, "data", reloaded.id.to_s, "#{reloaded.id}.json"))).to eq false
        # Ensure children are preserved in its new location
        expect(File.exist?(cloud_path.join(other_parent.id.to_s, "data", reloaded.id.to_s, "data", reloaded.member_ids.first.to_s, "#{reloaded.member_ids.first}.json"))).to eq true
        expect(File.exist?(cloud_path.join(parent.id.to_s, "data", reloaded.id.to_s, "data", reloaded.member_ids.first.to_s, "#{reloaded.member_ids.first}.json"))).to eq false
        # Ensure children binary content is preserved in new location
        file_set = Wayfinder.for(resource).members.first
        expect(File.exist?(cloud_path.join(other_parent.id.to_s, "data", resource.id.to_s, "data", file_set.id.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true
        expect(File.exist?(cloud_path.join(parent.id.to_s, "data", resource.id.to_s, "data", file_set.id.to_s, "example-#{file_set.original_file.id}.tif"))).to eq false
      end
    end
    context "when completing a preserved MVW" do
      it "deeply nests file sets" do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        volume = FactoryBot.create_for_repository(:pending_scanned_resource, files: [file])
        parent = FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: volume.id)
        change_set = ChangeSet.for(parent)
        change_set.validate(state: "complete")

        output = change_set_persister.save(change_set: change_set)
        expect(Wayfinder.for(output).preservation_object.metadata_node.use).to eq [Valkyrie::Vocab::PCDMUse.PreservedMetadata]
        expect(File.exist?(disk_preservation_path.join(parent.id.to_s, "#{parent.id}.json"))).to eq true
        expect(File.exist?(disk_preservation_path.join(parent.id.to_s, "data", parent.member_ids.first.to_s, "#{parent.member_ids.first}.json"))).to eq true
        file_set = Wayfinder.for(volume).members.first
        expect(File.exist?(disk_preservation_path.join(parent.id.to_s, "data", volume.id.to_s, "data", file_set.id.to_s, "example-#{file_set.original_file.id}.tif"))).to eq true
      end
    end
    context "when adding a file to a preserved resource", run_real_characterization: true, run_real_derivatives: true do
      with_queue_adapter :inline
      it "preserves it" do
        resource = FactoryBot.create_for_repository(:complete_scanned_resource)
        file = fixture_file_upload("files/example.tif", "image/tiff")
        change_set_persister.buffer_into_index do |buffered_change_set_persister|
          change_set = ChangeSet.for(resource)
          buffered_change_set_persister.save(change_set: change_set)
        end
        start_checksum = Wayfinder.for(resource).preservation_objects[0].metadata_node.checksum
        reloaded = change_set_persister.query_service.find_by(id: resource.id)
        expect(Wayfinder.for(reloaded).preservation_object.metadata_node).to be_present
        output = nil
        change_set_persister.buffer_into_index do |buffered_change_set_persister|
          change_set = ChangeSet.for(reloaded)
          change_set.validate(files: [file])

          output = buffered_change_set_persister.save(change_set: change_set)
        end
        result = change_set_persister.query_service.find_by(id: output.id)
        end_checksum = Wayfinder.for(resource).preservation_objects[0].metadata_node.checksum

        children = change_set_persister.query_service.find_members(resource: result)
        preservation_object = Wayfinder.for(children.first).preservation_object
        expect(preservation_object.binary_nodes).to be_present
        expect(preservation_object.binary_nodes[0].checksum).to eq children.first.original_file.checksum
        expect(preservation_object.binary_nodes[0].checksum[0].md5).to eq "2a28fb702286782b2cbf2ed9a5041ab1"
        expect(start_checksum).not_to eq end_checksum
      end
    end
  end
  context "when preserving a collection" do
    before do
      allow(PreserveChildrenJob).to receive(:perform_later)
    end

    it "does not preserve it's members" do
      collection = FactoryBot.create_for_repository(:collection)
      FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id)
      change_set = ChangeSet.for(collection)
      change_set.validate(state: "complete")
      change_set_persister.save(change_set: change_set)

      expect(PreserveChildrenJob).to have_received(:perform_later).exactly(0).times
    end
  end

  context "when uploading a PDF to a ScannedResource", run_real_characterization: true, run_real_derivatives: true do
    with_queue_adapter :inline
    it "characterizes" do
      file = fixture_file_upload("files/sample.pdf", "application/pdf")
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      file_set = Wayfinder.for(resource).members.first

      expect(file_set.primary_file.checksum).to be_present
    end
    it "creates resources which can be OCR'd" do
      file = fixture_file_upload("files/sample.pdf", "application/pdf")
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file], ocr_language: "eng")
      file_set = Wayfinder.for(resource).members.last

      expect(file_set.ocr_content).to be_present
    end
  end

  context "when telling an archival_media_collection to reorganize" do
    it "reorganizes" do
      stub_findingaid(pulfa_id: "C0652")
      stub_findingaid(pulfa_id: "C0652_c0377")
      coll = FactoryBot.create_for_repository(:archival_media_collection, source_metadata_identifier: "C0652")
      barcode_resource = FactoryBot.create_for_repository(:recording, local_identifier: "32101047382401")
      FactoryBot.create_for_repository(
        :recording,
        local_identifier: "unorganized",
        title: "[Unorganized Barcodes]",
        member_ids: [barcode_resource.id],
        member_of_collection_ids: [coll.id]
      )

      coll_change_set = ChangeSet.for(coll)
      coll_change_set.validate(reorganize: true)
      change_set_persister.save(change_set: coll_change_set)

      parent = Wayfinder.for(barcode_resource).parents.first
      expect(parent.source_metadata_identifier).to eq ["C0652_c0377"]
    end
  end

  describe "updating a VectorResource", run_real_characterization: true, run_real_derivatives: true do
    with_queue_adapter :inline

    before do
      allow(GeoserverPublishJob).to receive(:perform_later)
    end

    context "when setting the resource to takedown status" do
      it "triggers a geoserver publish job with a delete operation" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        vector_change_set = ChangeSet.for(reloaded_resource)
        vector_change_set.validate(state: "takedown")
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).to have_received(:perform_later).with(hash_including(operation: "delete"))
      end
    end

    context "when the title is changed" do
      it "triggers a geoserver publish job with an update operation" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, title: "Vector", files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        vector_change_set = ChangeSet.for(reloaded_resource)
        vector_change_set.validate(title: "New Vector Title")
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).to have_received(:perform_later).with(hash_including(operation: "update"))
      end
    end

    context "when the visibility is changed" do
      it "triggers a geoserver publish job with an update operation" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        vector_change_set = ChangeSet.for(reloaded_resource)
        vector_change_set.validate(visibility: "restricted")
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).to have_received(:perform_later).with(hash_including(operation: "update"))
      end
    end

    context "when setting the resource status to complete" do
      before do
        allow(GeoserverPublishJob).to receive(:perform_later)
      end

      it "triggers a geoserver publish job with a delete operation" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:takedown_vector_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        vector_change_set = ChangeSet.for(reloaded_resource)
        vector_change_set.validate(state: "complete")
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).to have_received(:perform_later).with(hash_including(operation: "update"))
      end
    end

    context "when the publisher is changed" do
      it "does not trigger a geoserver publish job" do
        file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
        reloaded_resource = query_service.find_by(id: resource.id)
        vector_change_set = ChangeSet.for(reloaded_resource)
        vector_change_set.validate(publisher: ["ESRI"])
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).not_to have_received(:perform_later).with(hash_including(operation: "update"))
      end
    end

    context "when the resource doesn't have an attached geo file" do
      it "does not trigger a geoserver publish job" do
        resource = FactoryBot.create_for_repository(:complete_open_vector_resource)
        vector_change_set = ChangeSet.for(resource)
        vector_change_set.validate(visibility: "restricted")
        change_set_persister.save(change_set: vector_change_set)

        expect(GeoserverPublishJob).not_to have_received(:perform_later)
      end
    end
  end

  context "when deleting a vector geo FileSet", run_real_characterization: true, run_real_derivatives: true do
    before do
      allow(GeoserverPublishJob).to receive(:perform_later)
      allow(GeoserverPublishJob).to receive(:perform_now)
    end

    it "runs a geoserver publish job synchronously with a derivatives_delete operation" do
      file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
      resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
      file_set = Wayfinder.for(resource).members.last
      file_set_change_set = ChangeSet.for(file_set)
      change_set_persister.delete(change_set: file_set_change_set)

      expect(GeoserverPublishJob).to have_received(:perform_now).with(hash_including(operation: "derivatives_delete"))
    end
  end

  context "when deleting a VectorResource", run_real_characterization: true, run_real_derivatives: true do
    before do
      allow(GeoserverPublishJob).to receive(:perform_later)
      allow(GeoserverPublishJob).to receive(:perform_now)
    end

    it "runs a geoserver publish job synchronously with a derivatives_delete operation" do
      file = fixture_file_upload("files/vector/shapefile.zip", "application/zip")
      resource = FactoryBot.create_for_repository(:complete_open_vector_resource, files: [file])
      vector_change_set = ChangeSet.for(resource)
      change_set_persister.delete(change_set: vector_change_set)

      expect(GeoserverPublishJob).to have_received(:perform_now).with(hash_including(operation: "delete"))
    end
  end

  context "when updating a RasterResource" do
    before do
      allow(GeoserverPublishJob).to receive(:perform_later)
    end

    it "does not trigger a geoserver publish job" do
      resource = FactoryBot.create_for_repository(:complete_open_raster_resource)
      raster_change_set = ChangeSet.for(resource)
      raster_change_set.validate(visibility: "restricted")
      change_set_persister.save(change_set: raster_change_set)

      expect(GeoserverPublishJob).not_to have_received(:perform_later)
    end
  end

  context "when deleting a raster geo FileSet", run_real_characterization: true, run_real_derivatives: true do
    before do
      allow(GeoserverPublishJob).to receive(:perform_now)
    end

    it "does not trigger a geoserver publish job" do
      file = fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff")
      resource = FactoryBot.create_for_repository(:complete_open_raster_resource, files: [file])
      file_set = Wayfinder.for(resource).members.last
      file_set_change_set = ChangeSet.for(file_set)
      change_set_persister.delete(change_set: file_set_change_set)

      expect(GeoserverPublishJob).not_to have_received(:perform_now)
    end
  end
end
