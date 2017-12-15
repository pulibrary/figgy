# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionDecorator do
  subject(:decorator) { described_class.new(collection) }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  it 'has no files which can be managed' do
    expect(decorator.manageable_files?).to be false
  end

  describe '#collections' do
    it "cannot have parent collections" do
      expect(decorator.collections).to be_empty
    end
  end

  describe '#parents' do
    it "cannot have parent resources" do
      expect(decorator.parents).to be_empty
    end
  end

  describe '#title' do
    it 'exposes the title' do
      expect(decorator.title).to eq 'Title'
    end
  end
end
