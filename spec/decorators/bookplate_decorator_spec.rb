# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BookplateDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:bookplate) }
  let(:resource_klass) { Bookplate }

  it_behaves_like 'a Valkyrie::ResourceDecorator'

  describe '.manageable_structure?' do
    it 'is does not have a logical structure' do
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe '#parents' do
    let(:parent_collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:bookplate, member_of_collection_ids: [parent_collection.id]) }

    before do
      parent_collection
    end

    it 'retrieves all parent resources' do
      expect(decorator.parents.to_a).not_to be_empty
    end
  end

  describe '#decorated_parent_resource' do
    let(:resource) { FactoryBot.create_for_repository(:bookplate) }
    let(:parent) { FactoryBot.create_for_repository(:bookplate, member_ids: [resource.id]) }

    before do
      parent
    end

    it 'retrieves all parent resources' do
      expect(decorator.decorated_parent_resource).to be_a described_class
    end
  end
end
