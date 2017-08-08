# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::EDM do
  before do
    class TestResource < Valhalla::Resource
      include Schema::EDM
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.rights_statement = 'test statement'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes EDM for a Valhalla::Resource subclass instances' do
      expect(resource.rights_statement).to include 'test statement'
    end
  end
end
