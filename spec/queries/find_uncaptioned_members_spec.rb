# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindUncaptionedMembers do
  with_queue_adapter :inline
  let(:query_service) { ChangeSetPersister.default.query_service }

  it "returns all child members that are uncaptioned" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video)
    file_set = Wayfinder.for(resource).file_sets.first

    uncaptioned_members = query_service.custom_queries.find_uncaptioned_members(resource: resource)
    # Ensure we get an empty set if we ask for something that doesn't have
    # member_ids.
    uncaptioned_file_set_members = query_service.custom_queries.find_uncaptioned_members(resource: file_set)

    expect(uncaptioned_members.length).to eq 1
    expect(uncaptioned_file_set_members).to eq []
  end

  it "can return count" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video)
    file_set = Wayfinder.for(resource).file_sets.first

    uncaptioned_members_count = query_service.custom_queries.find_uncaptioned_members(resource: resource, count: true)
    # Ensure we get 0 if we ask for something with no member_ids.
    file_set_uncaptioned_members_count = query_service.custom_queries.find_uncaptioned_members(resource: file_set, count: true)

    expect(uncaptioned_members_count).to eq 1
    expect(file_set_uncaptioned_members_count).to eq 0
  end

  it "doesn't return child members that are captioned" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions)

    uncaptioned_members = query_service.custom_queries.find_uncaptioned_members(resource: resource)

    expect(uncaptioned_members.length).to eq 0
  end

  it "doesn't return child members that are uncaptioned but captions_required is false" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_silent_video)

    uncaptioned_members = query_service.custom_queries.find_uncaptioned_members(resource: resource)

    expect(uncaptioned_members.length).to eq 0
  end
end
