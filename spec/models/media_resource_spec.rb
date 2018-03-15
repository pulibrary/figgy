# frozen_string_literal: true
# Generated with `rails generate valkyrie:model MediaResource`
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe MediaResource do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has ordered member_ids" do
    media = described_class.new
    media.member_ids = [1, 2, 3, 3]
    expect(media.member_ids).to eq [1, 2, 3, 3]
  end

  it "has bag validation attributes" do
    media = described_class.new
    media.bag_validation_success = 1
    expect(media.bag_validation_success).to eq 1
  end
end
