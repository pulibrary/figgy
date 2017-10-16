# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IndexCollection do
  subject(:index_collection) { FactoryGirl.build(:index_collection) }
  describe '#decorate' do
    it 'decorates an index collection' do
      expect(index_collection.decorate).to be_a IndexCollectionDecorator
    end
  end
  describe '#logical_structure' do
    it 'exposes the logical structure' do
      expect(index_collection.logical_structure).to eq []
    end
  end
end
