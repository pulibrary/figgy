# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "Ephemera Boxes", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:ephemera_box) do
    res = FactoryGirl.create_for_repository(:ephemera_box)
    adapter.persister.save(resource: res)
  end
  let(:ephemera_project) do
    res = FactoryGirl.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
    ephemera_project
  end

  context 'when an ephemera folder has been persisted with invalid data' do
    let(:change_set) do
      EphemeraBoxChangeSet.new(ephemera_box)
    end
    let(:change_set_persister) do
      PlumChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter)
    end

    before do
      change_set.barcode = '1234'
      change_set.sync
      change_set_persister.save(change_set: change_set)
    end

    scenario 'users see validation errors' do
      visit polymorphic_path [:edit, ephemera_box]
      expect(page.find(:css, ".has-error")).to have_content "has an invalid checkdigit"
    end
  end
end
