# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe EphemeraField do
  subject(:field) { described_class.new(name: 'test name') }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a name" do
    expect(field.name).to include 'test name'
  end
  it "has ordered member_ids" do
    field.member_ids = [1, 2, 3, 3]
    expect(field.member_ids).to eq [1, 2, 3, 3]
  end
end
