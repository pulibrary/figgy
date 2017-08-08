# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Schema::Plum do
  before do
    class TestResource < Valhalla::Resource
      include Schema::Plum
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context 'with a new Resource Class' do
    let(:resource) { TestResource.new }

    before do
      resource.title = 'test title1'
      resource.actor = 'test person'
      resource.sort_title = 'test title2'
      resource.portion_note = 'test value1'
      resource.rights_statement = 'test statement'
      resource.call_number = 'test value2'
      resource.edition = 'test edition'
      resource.nav_date = 'test date'
    end

    it 'mixes in the module' do
      expect(resource.class.ancestors).to include(described_class)
    end

    it 'defines the schema attributes Plum for a Valhalla::Resource subclass instances' do
      expect(resource.title).to include 'test title1'
      expect(resource.actor).to include 'test person'
      expect(resource.sort_title).to include 'test title2'
      expect(resource.portion_note).to include 'test value1'
      expect(resource.rights_statement).to include 'test statement'
      expect(resource.call_number).to include 'test value2'
      expect(resource.edition).to include 'test edition'
      expect(resource.nav_date).to include 'test date'
    end
  end
end
