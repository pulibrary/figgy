# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "LinkedData::Resource::WithDateRange" do
  subject(:linked_resource) { resource.linked_resource }
  before do
    raise "resource must be set with `let(:resource)`" unless defined? resource
    raise "resource_factory must be set with `let(:resource_factory)`" unless defined? resource_factory
  end

  it "exposes date_range values as a nested date range" do
    expect(linked_resource.date_range.first).to be_a Hash
    expect(linked_resource.as_jsonld["date_range"]).to eq linked_resource.date_range
  end

  context "when there's no date range" do
    let(:resource) { FactoryBot.create_for_repository(resource_factory) }
    it "doesn't add the field" do
      expect(linked_resource.as_jsonld["date_range"]).to be_blank
    end
  end

  context "when there's a blank date range" do
    let(:resource) { FactoryBot.create_for_repository(resource_factory, date_range: [DateRange.new]) }
    it "doesn't add the field" do
      expect(linked_resource.as_jsonld["date_range"]).to be_blank
    end
  end
end
