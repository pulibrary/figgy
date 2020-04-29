# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedImportedResource do
  let(:linked_resource) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, title: ["more", "than", "one", "title"]) }
  it "returns an array of titles" do
    expect(linked_resource.as_jsonld["title"]).to be_a Array
  end

  it "returns JSON-LD with a system_created_at/system_updated_at date" do
    expect(linked_resource.as_jsonld["system_created_at"]).to be_present
    expect(linked_resource.as_jsonld["system_updated_at"]).to be_present
  end
end
