# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::SCHEMA do
  before do
    class TestResource < Valhalla::Resource
      include Schema::SCHEMA
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.height = 'test value1'
      resource.width = 'test value2'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes SCHEMA for a Valhalla::Resource subclass instances' do
      expect(resource.height).to include 'test value1'
      expect(resource.width).to include 'test value2'
    end
  end
end
