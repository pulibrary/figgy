# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScannedResource::CDL::ResourceChangeSet do
  it "can be realized from ChangeSet.for" do
    expect(ChangeSet.for(ScannedResource.new(change_set: "ScannedResource::CDL::Resource"))).to be_a described_class
    expect(ChangeSet.for(ScannedResource.new(change_set: "CDL::Resource"))).to be_a described_class
  end

  it "has appropriate defaults" do
    change_set = described_class.new(ScannedResource.new)

    # Private visibility
    expect(change_set.visibility).to eq "restricted"
    expect(change_set.downloadable).to eq "none"
    expect(change_set.rights_statement).to eq RightsStatements.in_copyright
    # Don't preserve in-copyright material.
    expect(change_set.preserve?).to eq false
    # Use draft/complete workflow.
    expect(change_set.state).to eq "draft"
  end

  describe "#primary_terms" do
    it "has necessary terms for the form" do
      change_set = described_class.new(ScannedResource.new)

      expect(change_set.primary_terms).to include(
        :title,
        :source_metadata_identifier,
        :member_of_collection_ids,
        :rights_statement,
        :rights_note,
        :downloadable,
        :ocr_language,
        :portion_note,
        :append_id,
        :change_set
      )
    end
  end
end
