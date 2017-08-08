# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::BIBFRAME do
  before do
    class TestResource < Valhalla::Resource
      include Schema::BIBFRAME
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.edition = 'test edition'
      resource.geographic_origin = 'test origin'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes BIBFRAME for a Valhalla::Resource subclass instances' do
      expect(resource.edition).to include 'test edition'
      expect(resource.geographic_origin).to include 'test origin'
    end
  end
end
