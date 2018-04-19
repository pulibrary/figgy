# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ArchivalMediaCollection do
  subject(:collection) { FactoryBot.build(:archival_media_collection) }
  it "has a local_identifier" do
    expect(collection.local_identifier).to eq []
    collection.local_identifier = "AC044"
    expect(collection.local_identifier).to eq ["AC044"]
  end
end
