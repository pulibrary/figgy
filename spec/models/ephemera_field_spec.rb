# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe EphemeraField do
  subject(:field) { described_class.new(field_name: '1', member_of_vocabulary_id: 'test id') }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a name" do
    expect(field.field_name).to include '1'
  end
  it "belongs to a vocabulary" do
    expect(field.member_of_vocabulary_id).to include 'test id'
  end
end
