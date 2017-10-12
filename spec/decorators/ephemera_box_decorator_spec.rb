# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraBoxDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_box) }
  describe "decoration" do
    it "decorates an EphemeraBox" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'has a title' do
    expect(decorator.title).to eq('Box 1')
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
  it 'can attach folders' do
    expect(resource.decorate.attachable_objects).to include EphemeraFolder
  end
  context 'with folders' do
    let(:folder) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:ephemera_folder)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_box, member_ids: [folder.id]) }
    it 'retrieves folders' do
      expect(resource.decorate.folders.to_a).not_to be_empty
      expect(resource.decorate.folders.to_a.first).to be_a EphemeraFolder
    end
  end
end
