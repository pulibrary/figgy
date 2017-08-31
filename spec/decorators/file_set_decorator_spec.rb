# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSetDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:scanned_resource) }

  describe '#collections' do
    it "has no collections" do
      expect(decorator.collections).to eq []
    end
  end
end
