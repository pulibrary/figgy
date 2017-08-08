# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::OpaqueMods do
  before do
    class TestResource < Valhalla::Resource
      include Schema::OpaqueMods
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.sort_title = 'test title'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes OpaqueMods for a Valhalla::Resource subclass instances' do
      expect(resource.sort_title).to include 'test title'
    end
  end
end
