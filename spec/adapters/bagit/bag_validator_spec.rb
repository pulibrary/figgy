# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe Bagit::BagValidator do
  describe '#validate' do
    context 'when checksums for a bag are good' do
      let(:bag_path) { Rails.root.join('spec', 'fixtures', 'bags', 'good-bag') }
      it 'returns true' do
        expect(described_class.validate(bag_path: bag_path)).to be true
      end
    end

    context 'when a metadata checksum for a bag is bad' do
      let(:bag_path) { Rails.root.join('spec', 'fixtures', 'bags', 'bad-metadata') }
      it 'returns false' do
        expect(described_class.validate(bag_path: bag_path)).to be false
      end
    end

    context 'when data checksum for a bag is bad' do
      let(:bag_path) { Rails.root.join('spec', 'fixtures', 'bags', 'bad-data') }
      it 'returns false' do
        expect(described_class.validate(bag_path: bag_path)).to be false
      end
    end
  end
end
