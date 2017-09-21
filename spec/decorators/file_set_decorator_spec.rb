# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSetDecorator do
  subject(:decorator) { described_class.new(file_set) }
  let(:file_set) { FactoryGirl.create_for_repository(:file_set) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  it 'has no files which can be managed' do
    expect(decorator.manageable_files?).to be false
  end

  describe '#collections' do
    it "exposes parent collections" do
      expect(decorator.collections).to eq []
    end
  end

  describe '#parents' do
    it "exposes parent resources" do
      res = FactoryGirl.create_for_repository(:scanned_resource)
      res.member_ids = [file_set.id]
      parent = adapter.persister.save(resource: res)

      expect(decorator.parents).not_to be_empty
      expect(decorator.parents.first).to be_a parent.class
      expect(decorator.parents.first.id).to eq parent.id
    end
  end
end
