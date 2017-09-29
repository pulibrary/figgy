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
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
  it 'exposes markup for rights statement' do
    expect(resource.decorate.rendered_rights_statement).not_to be_empty
    expect(resource.decorate.rendered_rights_statement.first).to match(/#{Regexp.escape('http://rightsstatements.org/vocab/NKC/1.0/')}/)
  end
  context 'with controlled vocabulary terms' do
    let(:term) { FactoryGirl.create_for_repository(:ephemera_term) }
    let(:resource) { FactoryGirl.build(:ephemera_folder, geographic_origin: term.id) }
    it 'exposes values for the geographic origin as controlled terms' do
      expect(resource.decorate.geographic_origin).to be_a EphemeraTerm
      expect(resource.decorate.geographic_origin.id).to eq term.id
    end
    context 'which have been deleted' do
      let(:resource) { FactoryGirl.build(:ephemera_folder, geographic_origin: Valkyrie::ID.new('no-exist')) }

      it 'exposes values for the geographic origin as controlled terms' do
        allow(Rails.logger).to receive(:warn).with("Failed to find the resource no-exist")
        expect(resource.decorate.geographic_origin.id).to eq 'no-exist'
      end
    end
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
  context "within a box" do
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder) }
    it "can return the box it's a member of" do
      box = FactoryGirl.create_for_repository(:ephemera_box, member_ids: resource.id)

      expect(resource.decorate.ephemera_box.id).to eq box.id
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
