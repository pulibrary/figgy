# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::FOAF do
  before do
    class TestResource < Valhalla::Resource
      include Schema::FOAF
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.based_near = 'test location'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes FOAF for a Valhalla::Resource subclass instances' do
      expect(resource.based_near).to include 'test location'
    end
  end
end
