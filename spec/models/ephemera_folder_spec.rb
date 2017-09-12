# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe EphemeraFolder do
  subject(:folder) { described_class.new(title: 'test title') }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(folder.title).to include 'test title'
  end
  it "has ordered member_ids" do
    folder.member_ids = [1, 2, 3, 3]
    expect(folder.member_ids).to eq [1, 2, 3, 3]
  end
end
