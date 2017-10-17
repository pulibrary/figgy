# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraProjectDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.create_for_repository(:ephemera_project) }
  describe "decoration" do
    it "decorates an EphemeraProject" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'does not manage files' do
    expect(decorator.manageable_files?).to be false
  end
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
  describe '#slug' do
    it 'generates a slug' do
      expect(decorator.slug).to eq "test_project-1234"
    end
  end
  describe '#iiif_manifest_attributes' do
    it 'includes the "exhibit" property in the IIIF Manifest metadata' do
      expect(decorator.iiif_manifest_attributes).to include(exhibit: "test_project-1234")
    end
  end
end
