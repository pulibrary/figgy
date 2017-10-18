# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Valkyrie::ResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:scanned_resource) }

  describe '#members' do
    let(:child_resource) { FactoryGirl.create_for_repository(:scanned_resource) }
    let(:resource) { FactoryGirl.create_for_repository(:scanned_resource, member_ids: [child_resource.id]) }

    it 'retrieves all member resources' do
      expect(decorator.members.to_a).not_to be_empty
    end
  end

  describe '#parents' do
    let(:resource) { FactoryGirl.create_for_repository(:scanned_resource) }
    let(:parent_resource) { FactoryGirl.create_for_repository(:scanned_resource, member_ids: [resource.id]) }
    before do
      parent_resource
    end

    it 'retrieves all parent resources' do
      expect(decorator.parents.to_a).not_to be_empty
    end
  end
end
