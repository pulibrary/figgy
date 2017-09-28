# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe VectorWork do
  subject(:vector_work) { described_class.new(title: 'test title') }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(vector_work.title).to include 'test title'
  end
  it "can have manifests" do
    expect(vector_work.class.can_have_manifests?).to be false
  end
end
