# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BookplateDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:bookplate) }
  describe "#rendered_rights_statement" do
    it "returns an HTML rights statement" do
      term = ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first)
      expect(decorator.rendered_rights_statement.length).to eq 1
      expect(decorator.rendered_rights_statement.first).to include term.definition
      expect(decorator.rendered_rights_statement.first).to include I18n.t("valhalla.works.show.attributes.rights_statement.boilerplate")
      expect(decorator.rendered_rights_statement.first).to include '<a href="http://rightsstatements.org/vocab/NKC/1.0/">No Known Copyright</a>'
    end
  end
  describe '#created' do
    let(:resource) do
      FactoryBot.build(:bookplate,
                       title: 'test title',
                       created: '01/01/1970')
    end
    it 'exposes a formatted string for the created date' do
      expect(decorator.created).to eq ["January 1, 1970"]
    end
  end
  context 'within a collection' do
    let(:collection) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:collection)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:bookplate, member_of_collection_ids: [collection.id]) }
    it 'retrieves the title of parents' do
      expect(resource.decorate.member_of_collections).not_to be_empty
      expect(resource.decorate.member_of_collections.first).to be_a CollectionDecorator
      expect(resource.decorate.member_of_collections.first.title).to eq 'Title'
    end
  end
end
