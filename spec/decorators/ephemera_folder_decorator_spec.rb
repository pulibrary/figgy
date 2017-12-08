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

  context 'with subjects and categories' do
    let(:category) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'Art and Culture') }
    let(:subject_term) { FactoryGirl.create_for_repository(:ephemera_term, label: 'Architecture', member_of_vocabulary_id: category.id) }
    let(:category2) { FactoryGirl.create_for_repository(:ephemera_vocabulary, label: 'Economics') }
    let(:subject_term2) { FactoryGirl.create_for_repository(:ephemera_term, label: 'Economics', member_of_vocabulary_id: category2.id) }
    let(:resource) { FactoryGirl.build(:ephemera_folder, subject: [subject_term, subject_term2]) }
    it 'provides links to facets' do
      expect(resource.decorate.rendered_subject).to contain_exactly(
        "<a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Art+and+Culture\">Art and Culture</a> -- <a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Architecture\">Architecture</a>",
        "<a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Economics\">Economics</a>"
      )
    end
  end

  context 'with collections' do
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder, member_of_collection_ids: [collection.id]) }
    it 'retrieves all parent collections' do
      expect(resource.decorate.collections.to_a).not_to be_empty
      expect(resource.decorate.collections.to_a.first).to be_a Collection
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

  context "within a project" do
    let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder) }
    it "can return the box it's a member of" do
      project = FactoryGirl.create_for_repository(:ephemera_project, member_ids: resource.id)

      expect(resource.decorate.ephemera_project.id).to eq project.id
      expect(resource.decorate.ephemera_box).to be nil
    end
  end

  it 'exposes IIIF manifests' do
    expect(decorator.iiif_manifest_attributes).to include alternative_title: ['test alternative title']
    expect(decorator.iiif_manifest_attributes).to include barcode: ["12345678901234"]
    expect(decorator.iiif_manifest_attributes).to include contributor: ['test contributor']
    expect(decorator.iiif_manifest_attributes).to include creator: ['test creator']
    expect(decorator.iiif_manifest_attributes).to include date_created: ['1970/01/01']
    expect(decorator.iiif_manifest_attributes).to include description: ['test description']
    expect(decorator.iiif_manifest_attributes).to include dspace_url: ['http://example.com']
    expect(decorator.iiif_manifest_attributes).to include folder_number: ['one']
    expect(decorator.iiif_manifest_attributes).to include genre: ['test genre']
    expect(decorator.iiif_manifest_attributes).to include geo_subject: []
    expect(decorator.iiif_manifest_attributes).to include geographic_origin: []
    expect(decorator.iiif_manifest_attributes).to include height: ['20']
    expect(decorator.iiif_manifest_attributes).to include language: ['test language']
    expect(decorator.iiif_manifest_attributes).to include page_count: ['30']
    expect(decorator.iiif_manifest_attributes).to include publisher: ['test publisher']
    expect(decorator.iiif_manifest_attributes).to include series: ['test series']
    expect(decorator.iiif_manifest_attributes).to include sort_title: []
    expect(decorator.iiif_manifest_attributes).to include source_url: ['http://example.com']
    expect(decorator.iiif_manifest_attributes).to include subject: ["test subject"]
    expect(decorator.iiif_manifest_attributes).to include title: ['test folder']
    expect(decorator.iiif_manifest_attributes).to include width: ['10']
  end
end
