# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraTemplateDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_template) }
  describe "decoration" do
    it "decorates an EphemeraTemplate" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'does not manage files' do
    expect(decorator.manageable_files?).to be false
  end
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
  it 'exposes the metadata adapter' do
    expect(resource.decorate.metadata_adapter).to be_a Valkyrie::Persistence::Postgres::MetadataAdapter
  end
end
