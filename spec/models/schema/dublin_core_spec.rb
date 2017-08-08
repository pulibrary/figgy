# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::DublinCore do
  before do
    class TestResource < Valhalla::Resource
      include Schema::DublinCore
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.title = 'test title'
      resource.resource_type = 'test format'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes DublinCore for a Valhalla::Resource subclass instances' do
      expect(resource.title).to include 'test title'
      expect(resource.resource_type).to include 'test format'
    end
  end
end
