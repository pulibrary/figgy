# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::Ephemera do
  before do
    class TestResource < Valhalla::Resource
      include Schema::Ephemera
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.title = 'test title'
      resource.edition = 'test edition'
      resource.call_number = 'test value1'
      resource.height = 'test value2'
      resource.folder_number = 'test value3'
      resource.page_count = 'test value4'
      resource.sort_title = 'test title2'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes Ephemera for a Valhalla::Resource subclass instances' do
      expect(resource.title).to include 'test title'
      expect(resource.edition).to include 'test edition'
      expect(resource.call_number).to include 'test value1'
      expect(resource.height).to include 'test value2'
      expect(resource.folder_number).to include 'test value3'
      expect(resource.page_count).to include 'test value4'
      expect(resource.sort_title).to include 'test title2'
    end
  end
end
