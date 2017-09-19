# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "Ephemera Terms", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:ephemera_project) do
    res = FactoryGirl.create_for_repository(:ephemera_project)
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  context 'when users have added a controlled vocabulary' do
    let(:ephemera_vocabulary) do
      res = FactoryGirl.create_for_repository(:ephemera_vocabulary)
      adapter.persister.save(resource: res)
    end

    context 'when users have added terms to the vocabulary' do
      let(:ephemera_term) { FactoryGirl.create_for_repository(:ephemera_term) }

      before do
        ephemera_term.member_of_vocabulary_id = ephemera_vocabulary.id
        adapter.persister.save(resource: ephemera_term)
      end

      scenario 'users can view existing terms' do
        visit ephemera_terms_path
        expect(page.find(:css, 'td.vocab:first-child')).to have_content 'test term'
      end

      scenario 'users can view an existing term' do
        visit Valhalla::ContextualPath.new(child: ephemera_term).show
        expect(page).to have_content 'test term'
      end

      scenario 'users can edit existing terms' do
        visit polymorphic_path [:edit, ephemera_term]
        page.fill_in 'ephemera_term_label', with: 'updated label'
        page.find('form.edit_ephemera_term').native.submit

        expect(page).to have_content 'updated label'
      end

      scenario 'users can delete existing terms' do
        visit Valhalla::ContextualPath.new(child: ephemera_term).show

        page.accept_confirm do
          click_link "Delete This Ephemera Term"
        end

        expect(page.find(:css, ".alert-info")).to have_content "Deleted EphemeraTerm"
      end
    end
  end
end
