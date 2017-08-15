# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RemoteRecord, type: :model do
  describe '.retrieve' do
    context 'with a Voyager record ID' do
      it 'constructs a RemoteRecord instance' do
        expect(described_class.retrieve('4609321')).to be_a RemoteRecord
      end
    end

    context 'with a PULFA record ID' do
      it 'constructs a PulfaRecord instance' do
        expect(described_class.retrieve('AC044_c0003')).to be_a RemoteRecord::PulfaRecord
      end
    end
  end

  describe '.bibdata?' do
    context 'with a Voyager record ID' do
      it 'validates that this is a bib. ID' do
        expect(described_class.bibdata?('4609321')).to be_truthy
      end
    end

    context 'with a PULFA record ID' do
      it 'validates that this is a not a bib. ID' do
        expect(described_class.bibdata?('AC044_c0003')).to be_falsy
      end
    end
  end

  describe '.source_metadata_url' do
    context 'with a Voyager record ID' do
      it 'validates that this is not a bib. ID' do
        expect(described_class.source_metadata_url('4609321')).to eq 'https://bibdata.princeton.edu/bibliographic/4609321'
      end
    end

    context 'with a PULFA record ID' do
      it 'validates that this is a bib. ID' do
        expect(described_class.source_metadata_url('AC044_c0003')).to eq 'https://findingaids.princeton.edu/collections/AC044/c0003.xml?scope=record'
      end
    end
  end
end
