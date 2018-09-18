# frozen_string_literal: true
# Generated with `rails generate valkyrie:model MediaResource`
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe MediaResource do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has ordered member_ids" do
    media = described_class.new
    media.member_ids = [1, 2, 3, 3]
    expect(media.member_ids).to eq [1, 2, 3, 3]
  end

  describe "#upload_set_id" do
    it "is a Valkyrie::ID" do
      media = described_class.new
      media.upload_set_id = Valkyrie::ID.new(SecureRandom.uuid)
      expect(media.upload_set_id).to be_a Valkyrie::ID
    end
  end
end
