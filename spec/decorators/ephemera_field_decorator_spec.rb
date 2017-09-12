# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFieldDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_field) }
  describe "decoration" do
    it "decorates an EphemeraField" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'does not manage files' do
    expect(decorator.manageable_files?).to be false
  end
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
  it 'exposes the metadata adapter' do
    expect(resource.decorate.metadata_adapter).to be_a Valkyrie::Persistence::Postgres::MetadataAdapter
  end
  context 'within a project' do
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_field) }
    before do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      project = FactoryGirl.build(:ephemera_project)
      project.member_ids = [resource.id]
      adapter.persister.save(resource: project)
    end

    it 'retrieves the title of parents' do
      expect(resource.decorate.projects.to_a).not_to be_empty
      expect(resource.decorate.projects.to_a.first).to be_a EphemeraProject
    end
  end
end
