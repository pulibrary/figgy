# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::NFO do
  before do
    class TestResource < Valhalla::Resource
      include Schema::NFO
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.page_count = 'test value'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes NFO for a Valhalla::Resource subclass instances' do
      expect(resource.page_count).to include 'test value'
    end
  end
end
