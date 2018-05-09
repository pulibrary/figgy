# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:ephemera_folder) }

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
    let(:term) { FactoryBot.create_for_repository(:ephemera_term) }
    let(:resource) { FactoryBot.build(:ephemera_folder, geographic_origin: term.id) }
    it 'exposes values for the geographic origin as controlled terms' do
      expect(resource.decorate.geographic_origin).to be_a EphemeraTerm
      expect(resource.decorate.geographic_origin.id).to eq term.id
    end
    context 'which have been deleted' do
      let(:resource) { FactoryBot.build(:ephemera_folder, geographic_origin: Valkyrie::ID.new('no-exist')) }

      it 'exposes values for the geographic origin as controlled terms' do
        allow(Rails.logger).to receive(:warn).with("Failed to find the resource no-exist")
        expect(resource.decorate.geographic_origin.id).to eq 'no-exist'
      end
    end
  end

  context 'with subjects and categories' do
    let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: 'Art and Culture') }
    let(:subject_term) { FactoryBot.create_for_repository(:ephemera_term, label: 'Architecture', member_of_vocabulary_id: category.id) }
    let(:category2) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: 'Economics') }
    let(:subject_term2) { FactoryBot.create_for_repository(:ephemera_term, label: 'Economics', member_of_vocabulary_id: category2.id) }
    let(:resource) { FactoryBot.build(:ephemera_folder, subject: [subject_term, subject_term2]) }
    it 'provides links to facets' do
      expect(resource.decorate.rendered_subject).to contain_exactly(
        "<a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Art+and+Culture\">Art and Culture</a> -- <a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Architecture\">Architecture</a>",
        "<a href=\"/?f%5Bdisplay_subject_ssim%5D%5B%5D=Economics\">Economics</a>"
      )
    end
  end

  context 'with collections' do
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, member_of_collection_ids: [collection.id]) }
    it 'retrieves all parent collections' do
      expect(resource.decorate.collections.to_a).not_to be_empty
      expect(resource.decorate.collections.to_a.first).to be_a Collection
    end
  end

  context 'with file sets' do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, member_ids: [file_set.id]) }
    it 'retrieves members' do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end

  # rubocop:disable RSpec/NestedGroups
  context "within a box" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id, state: "new") }
    before { box }

    it "can return the box it's a member of" do
      expect(resource.decorate.ephemera_box.id).to eq box.id
    end

    describe 'manifestable_state?' do
      describe 'the box is not all in production' do
        it 'returns true when in a manifestable state' do
          resource.state = ["complete"]
          expect(resource.decorate.manifestable_state?).to eq true
        end
        it 'returns false when in a non-manifestable state' do
          resource.state = ['needs_qa']
          expect(resource.decorate.manifestable_state?).to eq false
        end
      end

      describe 'the box is all in production' do
        let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id, state: "all_in_production") }
        it 'returns true when in a non-manifestable state' do
          resource.state = ['needs_qa']
          expect(resource.decorate.manifestable_state?).to eq true
        end
      end
    end

    describe 'public_readable_state?' do
      describe 'the box is not all in production' do
        it 'returns true when in a readable state' do
          resource.state = ["complete"]
          expect(resource.decorate.public_readable_state?).to eq true
        end
      end

      describe 'the box is all in production' do
        let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id, state: "all_in_production") }
        it 'returns true when in a non-readable state' do
          resource.state = ['needs_qa']
          expect(resource.decorate.public_readable_state?).to eq true
        end
      end
    end

    describe 'index_read_groups?' do
      describe 'the box is not all in production' do
        it 'returns true when in a read-group-indexable state' do
          resource.state = ["complete"]
          expect(resource.decorate.index_read_groups?).to eq true
        end
        it 'returns false when in a non-read-group-indexable state' do
          resource.state = ['needs_qa']
          expect(resource.decorate.index_read_groups?).to eq false
        end
      end

      describe 'the box is all in production' do
        let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: resource.id, state: "all_in_production") }
        it 'returns true when in a non-read-group-indexable state' do
          resource.state = ['needs_qa']
          expect(resource.decorate.index_read_groups?).to eq true
        end
      end
    end
  end
  # rubocop:enable RSpec/NestedGroups

  context "within a project" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }
    it "can return the box it's a member of" do
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: resource.id)

      expect(resource.decorate.ephemera_project.id).to eq project.id
      expect(resource.decorate.ephemera_box).to be nil
    end

    describe 'manifestable_state?' do
      it 'returns true when in a manifestable state' do
        resource.state = ["complete"]
        expect(resource.decorate.manifestable_state?).to eq true
      end
      it 'returns false when in a non-manifestable state' do
        resource.state = ['needs_qa']
        expect(resource.decorate.manifestable_state?).to eq false
      end
    end

    describe 'public_readable_state?' do
      it 'returns true when in a readable state' do
        resource.state = ["complete"]
        expect(resource.decorate.public_readable_state?).to eq true
      end
    end

    describe 'index_read_groups?' do
      it 'returns true when in a read-group-indexable state' do
        resource.state = ["complete"]
        expect(resource.decorate.index_read_groups?).to eq true
      end

      it 'returns false when in a non-read-group-indexable state' do
        resource.state = ['needs_qa']
        expect(resource.decorate.index_read_groups?).to eq false
      end
    end
  end

  context 'when viewing an Ephemera Project' do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_project, slug: "lae-d957") }
    let(:metadata) { resource.decorate.iiif_metadata }

    it 'returns slug attributes as exhibit' do
      expect(metadata).to be_an Array
      expect(metadata).to include "label" => "Exhibit", "value" => ["lae-d957"]
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
    expect(decorator.iiif_manifest_attributes).to include source_url: ['http://example.com']
    expect(decorator.iiif_manifest_attributes).to include subject: ["test subject"]
    expect(decorator.iiif_manifest_attributes).to include title: ['test folder']
    expect(decorator.iiif_manifest_attributes).to include width: ['10']
  end

  context 'with an OCR language of english' do
    let(:resource) { FactoryBot.build(:ephemera_folder, ocr_language: 'eng', state: 'complete') }

    it 'generates markup for OCR languages' do
      expect(decorator.rendered_ocr_language).to eq ['English']
    end
  end
end
