# frozen_string_literal: true
require "rails_helper"

describe PlaylistWayfinder do
  subject(:playlist_wayfinder) { described_class.new(resource: resource) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:file_set1) do
    res = FileSet.new(title: "Symphony No. 14 in A major, K. 114")
    cs = FileSetChangeSet.new(res)
    change_set_persister.save(change_set: cs)
  end
  let(:file_set2) do
    res = FileSet.new(title: "Einleitung - I")
    cs = FileSetChangeSet.new(res)
    change_set_persister.save(change_set: cs)
  end
  let(:proxy1) do
    res = ProxyFileSet.new(proxied_file_id: file_set1.id)
    cs = ProxyFileSetChangeSet.new(res)
    change_set_persister.save(change_set: cs)
  end
  let(:proxy2) do
    res = ProxyFileSet.new(proxied_file_id: file_set2.id)
    cs = ProxyFileSetChangeSet.new(res)
    change_set_persister.save(change_set: cs)
  end
  let(:resource) do
    FactoryBot.create_for_repository(:playlist, member_ids: [proxy1.id, proxy2.id])
  end

  describe "#members" do
    let(:proxies) { playlist_wayfinder.members }

    it "retrieves the ProxyFileSets for a given Playlist" do
      expect(proxies.length).to eq(2)
      expect(proxies.first).to eq(proxy1)
      expect(proxies.last).to eq(proxy2)
    end
  end

  describe "#file_sets" do
    let(:file_sets) { playlist_wayfinder.file_sets }

    it "retrieves the FileSets for a given Playlist" do
      expect(file_sets.length).to eq(2)
      expect(file_sets).to include(file_set1)
      expect(file_sets).to include(file_set2)
    end
  end

  describe "#members" do
    let(:file_sets) { playlist_wayfinder.file_sets }

    it "retrieves the FileSets for a given Playlist" do
      expect(file_sets.length).to eq(2)
      expect(file_sets).to include(file_set1)
      expect(file_sets).to include(file_set2)
    end
  end
end
