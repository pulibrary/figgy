# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe MediainfoCharacterizationService do
  let(:file_characterization_service) { described_class }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:resource) do
    attributes = { id: SecureRandom.uuid, use: [Valkyrie::Vocab::PCDMUse.OriginalFile, Valkyrie::Vocab::PCDMUse.PreservationFile] }
    file_metadata_node = FileMetadata.for(file: file).new(attributes)
    allow(FileMetadata).to receive(:for).and_return(file_metadata_node)

    change_set_persister.save(change_set: RecordingChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:members) { query_service.find_members(resource: resource) }
  let(:valid_file_set) { members.first }
  let(:parent) { FactoryBot.create_for_repository(:scanned_resource, change_set: "recording") }
  let(:tracks) { double }
  let(:track_attributes) { double }
  let(:file) { fixture_file_upload("files/sample.ogg", "audio/ogg") }

  before do
    allow(track_attributes).to receive(:encoded_date).and_return nil
    allow(track_attributes).to receive(:producer).and_return(nil)
    allow(track_attributes).to receive(:originalsourceform).and_return(nil)
    allow(track_attributes).to receive(:duration).and_return(23_123)
    allow(track_attributes).to receive(:count).and_return 1
    allow(track_attributes).to receive(:filesize).and_return 1
    allow(tracks).to receive(:track_types).and_return(["general"])

    allow(tracks).to receive(:general).and_return(track_attributes)
    allow(tracks).to receive(:audio).and_return(nil)
    allow(tracks).to receive(:video).and_return(nil)
    allow(tracks).to receive(:audio?).and_return(true)
    allow(tracks).to receive(:video?).and_return(false)

    allow(MediaInfo).to receive(:from).and_return(tracks)
  end

  it "extracts empty and valid technical metadata attributes using the general track" do
    new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)
    expect(new_file_set.original_file.mime_type).to eq ["audio/ogg"]
    expect(new_file_set.original_file.date_of_digitization).to be_empty
    expect(new_file_set.original_file.producer).to be_empty
    expect(new_file_set.original_file.source_media_type).to be_empty
    expect(new_file_set.original_file.duration).to eq ["23.123"]
  end

  context "with a corrupt file or unsupported format" do
    before do
      allow(MediaInfo).to receive(:from).and_raise(ArgumentError)
      allow(Valkyrie.logger).to receive(:warn)
    end

    it "sets technical metadata attributes empty" do
      new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)

      expect(Valkyrie.logger).to have_received(:warn).at_least(:once).with(/MediainfoCharacterizationService\: Failed to characterize/)
      expect(new_file_set.original_file.mime_type).to eq ["audio/ogg"]
      expect(new_file_set.original_file.date_of_digitization).to be_empty
      expect(new_file_set.original_file.producer).to be_empty
      expect(new_file_set.original_file.source_media_type).to be_empty
      expect(new_file_set.original_file.duration).to be_empty
    end
  end

  context "with an audio file that has an apostrophe in it" do
    let(:file) { fixture_file_upload("files/audio's.wav", "audio/x-wav") }
    it "pulls the mime type" do
      new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)

      expect(new_file_set.original_file.mime_type).to eq ["audio/x-wav"]
    end
  end

  context "with an audio file" do
    let(:file) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "audio/x-wav") }
    let(:audio_track_attributes) { double }
    before do
      allow(audio_track_attributes).to receive(:encoded_date).and_return Time.zone.parse("UTC 2009-03-30 19:49:13")
      allow(audio_track_attributes).to receive(:producer).and_return("Test Producer")
      allow(audio_track_attributes).to receive(:originalsourceform).and_return("cassette")
      allow(audio_track_attributes).to receive(:duration).and_return(261)
      allow(audio_track_attributes).to receive(:count).and_return 1
      allow(audio_track_attributes).to receive(:filesize).and_return 1

      allow(tracks).to receive(:track_types).and_return(["audio"])
      allow(tracks).to receive(:audio).and_return(audio_track_attributes)
      allow(tracks).to receive(:video).and_return(nil)

      allow(MediaInfo).to receive(:from).and_return(tracks)
    end

    it "extracts the technical metadata from the audio track" do
      new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)

      expect(new_file_set.original_file.mime_type).to eq ["audio/x-wav"]
      expect(new_file_set.original_file.date_of_digitization).to eq [Time.zone.parse("UTC 2009-03-30 19:49:13")]
      expect(new_file_set.original_file.producer).to eq ["Test Producer"]
      expect(new_file_set.original_file.source_media_type).to eq ["cassette"]
      expect(new_file_set.original_file.duration).to eq ["0.261"]
    end

    context "when a file set contains a preservation audio file and an intermediate audio file" do
      it "characterizes both files" do
        preservation = fixture_file_upload("files/audio_file.wav", "audio/x-wav", Valkyrie::Vocab::PCDMUse.PreservationFile)
        recording = FactoryBot.create_for_repository(:recording, files: [preservation])
        file_set = query_service.find_members(resource: recording).first
        IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "files", "audio_file.wav"), file_set_id: file_set.id)
        file_set = query_service.find_members(resource: recording).first
        expect(file_set.file_metadata[0].checksum).not_to be_empty
        expect(file_set.file_metadata[1].checksum).not_to be_empty
      end
    end
  end

  context "with a video file" do
    let(:file) { fixture_file_upload("files/city.mp4", "video/mp4") }
    let(:audio_track_attributes) { double }
    let(:video_track_attributes) { double }
    before do
      allow(video_track_attributes).to receive(:encoded_date).and_return Time.zone.parse("UTC 2010-02-12 13:45:09")
      allow(video_track_attributes).to receive(:producer).and_return("Test Video Producer")
      allow(video_track_attributes).to receive(:originalsourceform).and_return("DAV")
      allow(video_track_attributes).to receive(:duration).and_return(0.984)
      allow(video_track_attributes).to receive(:count).and_return 1
      allow(video_track_attributes).to receive(:filesize).and_return 1

      allow(audio_track_attributes).to receive(:encoded_date).and_return Time.zone.parse("UTC 2009-03-30 19:49:13")
      allow(audio_track_attributes).to receive(:producer).and_return("Test Producer")
      allow(audio_track_attributes).to receive(:originalsourceform).and_return("cassette")
      allow(audio_track_attributes).to receive(:duration).and_return(261)
      allow(audio_track_attributes).to receive(:count).and_return 1
      allow(audio_track_attributes).to receive(:filesize).and_return 1
      allow(tracks).to receive(:track_types).and_return(["video", "audio"])

      allow(tracks).to receive(:video).and_return(video_track_attributes)
      allow(tracks).to receive(:audio).and_return(audio_track_attributes)
      allow(tracks).to receive(:video?).and_return(true)

      allow(MediaInfo).to receive(:from).and_return(tracks)
    end

    it "extracts the technical metadata from the video track" do
      new_file_set = described_class.new(file_set: valid_file_set, persister: persister).characterize(save: false)

      expect(new_file_set.original_file.mime_type).to eq ["video/mp4"]
      expect(new_file_set.original_file.date_of_digitization).to eq [Time.zone.parse("UTC 2010-02-12 13:45:09")]
      expect(new_file_set.original_file.producer).to eq ["Test Video Producer"]
      expect(new_file_set.original_file.source_media_type).to eq ["DAV"]
      expect(new_file_set.original_file.duration).to eq ["0.984"]
    end
  end

  describe "#valid?" do
    let(:decorator) { instance_double(FileSetDecorator, parent: parent) }

    before do
      allow(valid_file_set).to receive(:decorate).and_return(decorator)
    end

    it "is invalid without a media resource parent and supported media type" do
      expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
    end

    context "with a scanned resource parent" do
      let(:parent) { ScannedResource.new }
      it "is invalid without a supported media type" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be false
      end
    end

    context "with a supported media type" do
      let(:file) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "audio/x-wav") }

      it "is valid" do
        expect(described_class.new(file_set: valid_file_set, persister: persister).valid?).to be true
      end
    end
  end
end
