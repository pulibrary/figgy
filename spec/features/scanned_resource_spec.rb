# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "Scanned Resources", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  let(:volume1) do
    persister.save(resource: FactoryGirl.create_for_repository(:scanned_resource, title: 'vol1'))
  end
  let(:multi_volume_work) do
    persister.save(resource: FactoryGirl.create_for_repository(:scanned_resource, member_ids: [volume1.id]))
  end

  before do
    sign_in user
    multi_volume_work
  end

  context 'within a multi-volume work' do
    scenario 'the volumes are displayed as members' do
      visit solr_document_path(multi_volume_work)

      expect(page).to have_selector 'h2', text: 'Members'
      expect(page).to have_selector 'td', text: 'vol1'
    end
  end
end
