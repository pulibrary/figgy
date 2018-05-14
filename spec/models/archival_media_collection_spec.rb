# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaCollection do
  subject(:collection) { FactoryBot.build(:archival_media_collection) }
  it "has a source_metadata_identifier" do
    expect(collection.source_metadata_identifier).to eq nil
    collection.source_metadata_identifier = "AC044"
    expect(collection.source_metadata_identifier).to contain_exactly "AC044"
  end
end
