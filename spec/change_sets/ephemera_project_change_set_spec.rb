# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraProjectChangeSet do
  subject(:change_set) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_project) }
  describe '#title' do
    it 'accesses the title of an Ephemera Project' do
      expect(change_set.title).to include 'Test Project'
    end
  end

  describe '#slug' do
    it 'accesses the slug assigned to an Ephemera Project' do
      expect(change_set.slug).to include 'test_project-1234'
    end
  end

  describe '#langugae_options' do
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [ephemera_field.id]) }
    let(:ephemera_field) { FactoryGirl.create_for_repository(:ephemera_field, member_of_vocabulary_id: [ephemera_vocabulary.id]) }
    let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }
    it 'returns terms from the language field' do
      eng = FactoryGirl.create_for_repository(:ephemera_term, label: 'English', member_of_vocabulary_id: [ephemera_vocabulary.id])
      por = FactoryGirl.create_for_repository(:ephemera_term, label: 'Portuguese', member_of_vocabulary_id: [ephemera_vocabulary.id])
      expect(change_set.language_options.size).to eq 2
      expect(change_set.language_options).to include eng
      expect(change_set.language_options).to include por
    end
  end

  describe '#member_ids' do
    let(:ephemera_box) { FactoryGirl.create_for_repository(:ephemera_box) }
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id]) }
    before do
      ephemera_box
    end
    it 'accesses the IDs of member resources for an Ephemera Project' do
      expect(change_set.member_ids).to include ephemera_box.id
    end
  end

  describe '#primary_terms' do
    it 'exposes the title, slug, and top_language as the primary terms for Ephemera Projects' do
      expect(change_set.primary_terms).to eq [:title, :slug, :top_language]
    end
  end

  describe '#validate' do
    let(:existing_resource) { FactoryGirl.create_for_repository(:ephemera_project, slug: 'test_project-1234') }
    before do
      existing_resource
    end
    it 'ensures that only unique slugs can be persisted' do
      expect(change_set.validate(slug: 'test_project-1234')).to be false
    end
    it 'ensures that only valid slugs can be persisted' do
      expect(change_set.validate(slug: 'test_project-!@#$')).to be false
    end
  end
end
