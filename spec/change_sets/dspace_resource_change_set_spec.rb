# frozen_string_literal: true

require "rails_helper"

describe DspaceResourceChangeSet do
  subject(:dspace_resource_change_set) { described_class.new(scanned_resource) }
  let(:scanned_resource) { ScannedResource.new }

  it "does not apply remote metadata" do
    expect(dspace_resource_change_set.apply_remote_metadata?).to be false
  end
end
