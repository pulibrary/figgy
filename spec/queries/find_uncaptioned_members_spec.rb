# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindUncaptionedMembers do
  with_queue_adapter :inline
  let(:query_service) { ChangeSetPersister.default.query_service }
  it "returns all child members that are uncaptioned" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video)

    uncaptioned_members = query_service.custom_queries.find_uncaptioned_members(resource: resource)

    expect(uncaptioned_members.length).to eq 1
  end
  it "doesn't return child members that are captioned" do
    resource = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions)

    uncaptioned_members = query_service.custom_queries.find_uncaptioned_members(resource: resource)

    expect(uncaptioned_members.length).to eq 0
  end
end
