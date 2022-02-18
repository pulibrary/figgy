# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Bagit::QueryService do
  let(:adapter) do
    Bagit::MetadataAdapter.new(
      base_path: Rails.root.join("tmp", "bags")
    )
  end
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  before do
    persister.wipe!
  end
  it_behaves_like "a Valkyrie query provider"
end
