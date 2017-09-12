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
end
