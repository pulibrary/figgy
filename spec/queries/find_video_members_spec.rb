# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindVideoMembers do
  with_queue_adapter :inline
  let(:query_service) { ChangeSetPersister.default.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  it "returns all child members that are videos" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video)

    videos = query_service.custom_queries.find_video_members(resource: resource)

    expect(videos.length).to eq 1
  end

  it "doesn't return children that aren't videos" do
    resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

    videos = query_service.custom_queries.find_video_members(resource: resource)

    expect(videos.length).to eq 0
  end

  it "can return a count" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video)

    videos_count = query_service.custom_queries.find_video_members(resource: resource, count: true)

    expect(videos_count).to eq 1
  end
end
