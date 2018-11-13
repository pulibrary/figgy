# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe PlaylistDecorator do
  subject(:decorator) { described_class.new(playlist) }
  let(:playlist) { FactoryBot.create_for_repository(:playlist) }

  it "does not manage structure" do
    expect(decorator.manageable_structure?).to be false
  end

  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end

  it "does order files" do
    expect(decorator.orderable_files?).to be true
  end

  it "delegates members to wayfinder" do
    expect(decorator.members).to be_empty
  end

  describe "#title" do
    it "uses the title" do
      expect(decorator.title).to eq playlist.title
    end
  end

  describe "#proxies" do
    let(:file) { fixture_file_upload("files/audio_file.wav") }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file_set) { scanned_resource.decorate.members.first }
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
    let(:playlist) do
      res = Playlist.new
      cs = PlaylistChangeSet.new(res)
      cs.prepopulate!
      cs.validate(file_set_ids: [file_set.id])
      change_set_persister.save(change_set: cs)
    end

    it "accesses the decorated ProxyFileSets" do
      expect(decorator.proxies).not_to be_empty
      expect(decorator.proxies.first).to be_a ProxyFileSetDecorator
    end
  end

  describe "#file_set_ids" do
    let(:file) { fixture_file_upload("files/audio_file.wav") }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:file_set) { scanned_resource.decorate.members.first }
    let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
    let(:playlist) do
      res = Playlist.new
      cs = PlaylistChangeSet.new(res)
      cs.prepopulate!
      cs.validate(file_set_ids: [file_set.id])
      change_set_persister.save(change_set: cs)
    end

    it "accesses the IDs for member FileSets" do
      expect(decorator.file_set_ids).not_to be_empty
      expect(decorator.file_set_ids.first).to eq(file_set.id)
    end
  end
end
