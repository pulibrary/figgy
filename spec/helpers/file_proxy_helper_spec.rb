# frozen_string_literal: true

require "rails_helper"

RSpec.describe FileProxyHelper do
  describe "#proxies_with_recording_data" do
    it "returns file_proxies as json with recording_url and recording_title added in" do
      file_sets = Array.new(2) { FactoryBot.create_for_repository(:file_set) }
      recording = FactoryBot.create_for_repository(:recording, member_ids: [file_sets[0].id, file_sets[1].id])
      proxy_file_set1 = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_sets[0].id)
      proxy_file_set2 = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_sets[1].id)
      playlist = FactoryBot.create_for_repository(:playlist, member_ids: [proxy_file_set1.id, proxy_file_set2.id])

      h = helper.proxies_with_recording_data(playlist)
      recording_url = "http://test.host/catalog/#{recording.id}"
      expect(h.map { |p| p["recording_url"] }).to eq [recording_url, recording_url]
      expect(h.first["recording_title"]).to eq recording.title.first
    end

    it "maps RDF::Literal titles to strings" do
      title = "Winelight"
      file_set = FactoryBot.create_for_repository(:file_set)
      FactoryBot.create_for_repository(:recording, member_ids: [file_set.id], title: RDF::Literal.new(title, language: :en))
      proxy_file_set = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_set.id)
      playlist = FactoryBot.create_for_repository(:playlist, member_ids: [proxy_file_set.id])

      h = helper.proxies_with_recording_data(playlist)
      expect(h.first["recording_title"]).to eq title
    end
  end
end
