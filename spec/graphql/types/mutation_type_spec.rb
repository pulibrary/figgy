# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::MutationType do
  describe "fields" do
    it "has an updateResource mutation" do
      expect(described_class).to have_field(:updateResource)
      expect(described_class.fields["updateResource"].mutation).to eq Mutations::UpdateResource
    end
  end
end
