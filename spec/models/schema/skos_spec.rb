# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::SKOS do
  before do
    class TestResource < Valhalla::Resource
      include Schema::SKOS
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.portion_note = 'test value'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes SKOS for a Valhalla::Resource subclass instances' do
      expect(resource.portion_note).to include 'test value'
    end
  end
end
