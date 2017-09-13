# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_folder) }
  describe "decoration" do
    it "decorates an EphemeraFolder" do
      expect(resource.decorate).to be_a described_class
    end
  end
  describe "decoration" do
    it "decorates an EphemeraFolder" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'manages files' do
    expect(decorator.manageable_files?).to be true
  end
  it 'manages structures' do
    expect(decorator.manageable_structure?).to be true
  end
  it 'exposes markup for rights statement' do
    expect(resource.decorate.rendered_rights_statement).not_to be_empty
    expect(resource.decorate.rendered_rights_statement.first).to match(/#{Regexp.escape('http://rightsstatements.org/vocab/NKC/1.0/')}/)
  end
  context 'with file sets' do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder, member_ids: [file_set.id]) }
    it 'retrieves members' do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end
  context 'within a collection' do
    let(:collection) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryGirl.build(:collection)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder, member_of_collection_ids: [collection.id]) }
    it 'retrieves the title of parents' do
      expect(resource.decorate.member_of_collections.to_a).not_to be_empty
      expect(resource.decorate.member_of_collections.to_a.first).to eq 'Title'
    end
  end
  it 'exposes IIIF manifests' do
    expect(decorator.iiif_manifest_attributes).to include alternative_title: []
    expect(decorator.iiif_manifest_attributes).to include barcode: ["12345678901234"]
    expect(decorator.iiif_manifest_attributes).to include contributor: []
    expect(decorator.iiif_manifest_attributes).to include creator: []
    expect(decorator.iiif_manifest_attributes).to include date_created: []
    expect(decorator.iiif_manifest_attributes).to include description: []
    expect(decorator.iiif_manifest_attributes).to include dspace_url: []
    expect(decorator.iiif_manifest_attributes).to include folder_number: ['one']
    expect(decorator.iiif_manifest_attributes).to include genre: ['test genre']
    expect(decorator.iiif_manifest_attributes).to include geo_subject: []
    expect(decorator.iiif_manifest_attributes).to include geographic_origin: []
    expect(decorator.iiif_manifest_attributes).to include height: ['20']
    expect(decorator.iiif_manifest_attributes).to include language: ['test language']
    expect(decorator.iiif_manifest_attributes).to include page_count: ['30']
    expect(decorator.iiif_manifest_attributes).to include publisher: []
    expect(decorator.iiif_manifest_attributes).to include series: []
    expect(decorator.iiif_manifest_attributes).to include sort_title: []
    expect(decorator.iiif_manifest_attributes).to include source_url: []
    expect(decorator.iiif_manifest_attributes).to include subject: []
    expect(decorator.iiif_manifest_attributes).to include title: ['test folder']
    expect(decorator.iiif_manifest_attributes).to include width: ['10']
  end
end
