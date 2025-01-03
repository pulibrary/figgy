# frozen_string_literal: true
require "rails_helper"

RSpec.feature "PlaylistChangeSets" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:resource) do
    res = FactoryBot.create_for_repository(:playlist)
    persister.save(resource: res)
  end
  let(:change_set) do
    PlaylistChangeSet.new(resource)
  end
  let(:change_set_persister) do
    ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  before do
    change_set_persister.save(change_set: change_set)
    sign_in user
  end

  scenario "viewing a resource" do
    visit solr_document_path resource

    expect(page).to have_css ".attribute.title", text: "My Playlist"
    expect(page).to have_css ".attribute.visibility", text: "private"
  end

  context "when tracks have been added to a playlist" do
    let(:file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
    let(:recording) { FactoryBot.create_for_repository(:scanned_resource, files: [file], title: "Super Mario Theme") }
    let(:file_set) { recording.decorate.members.first }
    let(:change_set) do
      cs = PlaylistChangeSet.new(resource)
      cs.validate(file_set_ids: [file_set.id])
      cs
    end

    scenario "viewing, removing, adding tracks", js: true do
      persisted = adapter.query_service.find_by(id: resource.id)

      visit solr_document_path persisted

      members_table = page.find("table.member-recordings")
      within members_table do
        expect(page).to have_content(resource.decorate.members.first.title.first)
        click_button("Detach")
      end
      expect(page).not_to have_selector("table.member-recordings")

      tracks_div = page.find(".playlist-tracks")
      within tracks_div do
        fill_in("recording-query", with: "Super Mario Theme")
        click_button "Search"
        click_button "Add Track"
      end

      members_table = page.find("table.member-recordings")
      within members_table do
        expect(page).to have_content(resource.decorate.members.first.title.first)
      end
    end

    scenario "returning to search results" do
      persisted = adapter.query_service.find_by(id: resource.id)
      visit "/?f[human_readable_type_ssim][]=Playlist&q="
      visit solr_document_path persisted

      expect(page).to have_css('a[href="/?f%5Bhuman_readable_type_ssim%5D%5B%5D=Playlist&q="]', text: "Back to Search")
    end
  end

  def json_fixture(decorated_resource, recording)
    "[{\"id\":{\"id\":\"#{decorated_resource.id}\"},\"created_at\":\"#{decorated_resource.created_at}\",\"updated_at\":\"#{decorated_resource.updated_at}\",\"internal_resource\":\"ProxyFileSet\",\"new_record\":false,\"read_groups\":[],\"read_users\":[],\"edit_users\":[],\"edit_groups\":[],\"label\":[\"audio_file.wav\"],\"visibility\":[],\"proxied_file_id\":{\"id\":\"#{decorated_resource.proxied_file_id}\"},\"local_identifier\":null,\"recording_url\":\"http://www.example.com/catalog/#{recording.id}\",\"recording_title\":\"#{recording.title.first}\"}]"
  end
end
