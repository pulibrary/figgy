# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::Local do
  before do
    class TestResource < Valhalla::Resource
      include Schema::Local
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.call_number = 'test value1'
      resource.ocr_language = 'test value2'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes Plum::Local for a Valhalla::Resource subclass instances' do
      expect(resource.call_number).to include 'test value1'
      expect(resource.ocr_language).to include 'test value2'
    end
  end
end
