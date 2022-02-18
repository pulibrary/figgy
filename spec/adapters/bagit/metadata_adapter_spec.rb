# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Bagit::MetadataAdapter do
  let(:adapter) do
    described_class.new(
      base_path: Rails.root.join("tmp", "bags")
    )
  end
  it_behaves_like "a Valkyrie::MetadataAdapter"
end
