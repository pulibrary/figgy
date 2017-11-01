# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EditFieldHelper, type: :helper do
  describe 'reorder_languages' do
    let(:eng) { FactoryGirl.create_for_repository(:ephemera_term, label: 'English') }
    let(:por) { FactoryGirl.create_for_repository(:ephemera_term, label: 'Portuguese') }
    let(:spa) { FactoryGirl.create_for_repository(:ephemera_term, label: 'Spanish') }
    let(:languages) do
      [FactoryGirl.create_for_repository(:ephemera_term, label: 'Abkhazian').decorate,
       FactoryGirl.create_for_repository(:ephemera_term, label: 'Afar').decorate,
       eng.decorate,
       por.decorate,
       spa.decorate]
    end
    let(:top_languages) { [eng, por, spa] }
    it "pops English, Spanish, Portuguese to the top of the list" do
      reordered = helper.reorder_languages(languages, top_languages)
      expect(reordered.size).to eq 5
      expect(reordered.shift.label).to eq 'English'
      expect(reordered.shift.label).to eq 'Portuguese'
      expect(reordered.shift.label).to eq 'Spanish'
    end
  end
end
