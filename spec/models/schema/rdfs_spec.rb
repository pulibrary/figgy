# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::RDFS do
  before do
    class TestResource < Valhalla::Resource
      include Schema::RDFS
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.folder_number = 'test value'
      resource.related_url = 'http://testdomain'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes RDFS for a Valhalla::Resource subclass instances' do
      expect(resource.folder_number).to include 'test value'
      expect(resource.related_url).to include 'http://testdomain'
    end
  end
end
