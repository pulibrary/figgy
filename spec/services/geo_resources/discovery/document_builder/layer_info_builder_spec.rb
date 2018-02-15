# frozen_string_literal: true
require 'rails_helper'

describe GeoResources::Discovery::DocumentBuilder::LayerInfoBuilder do
  subject(:layer_info_builder) { described_class.new(geo_work) }

  let(:geo_work) { instance_double(VectorWorkDecorator) }
  let(:model_name) { 'VectorWork' }
  let(:document) { GeoResources::Discovery::GeoblacklightDocument.new }

  describe '#geom_type' do
    before do
      allow(geo_work).to receive(:model_name).and_return(model_name)
      allow(geo_work).to receive(:geo_members).and_return([])
      layer_info_builder.build(document)
    end

    context 'with a vector work' do
      it 'returns the geoblacklight vector geom type' do
        expect(document.geom_type).to eq 'Mixed'
      end
    end

    context 'with a scanned map' do
      let(:model_name) { 'ScannedMap' }

      it 'returns the geoblacklight image type' do
        expect(document.geom_type).to eq 'Image'
      end
    end

    context 'with a raster work' do
      let(:model_name) { 'RasterWork' }

      it 'returns the geoblacklight raster type' do
        expect(document.geom_type).to eq 'Raster'
      end
    end
  end
end
