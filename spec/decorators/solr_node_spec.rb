# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrNode do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:scanned_resource) }

  describe '#id' do
    it 'prepends a string for the ID' do
      expect(decorator.id).to match(/^id\-/)
    end
  end
end
