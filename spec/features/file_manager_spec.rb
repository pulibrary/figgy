# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "File Manager", js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file_set) { FactoryGirl.create_for_repository(:file_set) }
  let(:resource) do
    res = FactoryGirl.create_for_repository(:scanned_resource)
    res.member_ids = [file_set.id]
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  context 'without a derivative file' do
    let(:riiif_helper) { instance_double(ManifestBuilder::RiiifHelper) }
    let(:riiif_helper_class) { class_double(ManifestBuilder::RiiifHelper).as_stubbed_const(transfer_nested_constants: true) }
    before do
      allow(riiif_helper).to receive(:base_url).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      allow(riiif_helper_class).to receive(:new).and_return(riiif_helper)
    end
    scenario 'users visit the file management interface' do
      visit polymorphic_path [:file_manager, resource]

      expect(page).not_to have_selector('.thumbnail span.ignore-select')
    end
  end

  context 'with a derivative file' do
    let(:riiif_helper) { instance_double(ManifestBuilder::RiiifHelper) }
    let(:riiif_helper_class) { class_double(ManifestBuilder::RiiifHelper).as_stubbed_const(transfer_nested_constants: true) }
    before do
      allow(riiif_helper).to receive(:base_url).and_return('http://localhost/test-resource')
      allow(riiif_helper_class).to receive(:new).and_return(riiif_helper)
    end
    scenario 'users can visiting the file management interface' do
      visit polymorphic_path [:file_manager, resource]

      expect(page).to have_selector('.thumbnail span')
      expect(page).to have_selector('.thumbnail span.ignore-select')
    end
    context 'with a derivative service for images in the TIFF' do
      let(:create_derivatives_class) { class_double(CreateDerivativesJob).as_stubbed_const(transfer_nested_constants: true) }
      let(:original_file) { instance_double(FileMetadata) }
      before do
        allow(original_file).to receive(:mime_type).and_return('image/tiff')
        allow(file_set).to receive(:original_file).and_return(original_file)
        allow(create_derivatives_class).to receive(:perform_later).and_return(success: true)
      end
      scenario 'users regenerate derivatives for a file set' do
        visit polymorphic_path [:file_manager, resource]

        expect(page).to have_selector('form.rederive button')
        click_button 'Regenerate Derivatives'
        expect(page).to have_selector '.alert-success .text', text: 'Derivatives are being regenerated'
      end
      context 'when the derivative service fails' do
        before do
          allow(create_derivatives_class).to receive(:perform_later).and_raise(Hydra::Derivatives::TimeoutError)
        end
        scenario 'users cannot regenerate derivatives for a file set' do
          visit polymorphic_path [:file_manager, resource]

          expect(page).to have_selector('form.rederive button')
          click_button 'Regenerate Derivatives'
          expect(page).to have_selector '.alert-danger .text', text: 'Derivatives cannot be regenerated'
        end
      end
    end
  end

  context 'with a geo metadata file' do
    let(:original_file) { FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.OriginalFile, mime_type: 'application/xml; schema=fgdc') }
    let(:extractor) { instance_double(GeoMetadataExtractor) }
    let(:resource) do
      res = FactoryGirl.create_for_repository(:scanned_map)
      res.member_ids = [file_set.id]
      adapter.persister.save(resource: res)
    end

    before do
      file_set.file_metadata = [original_file]
      adapter.persister.save(resource: file_set)
      allow(GeoMetadataExtractor).to receive(:new).and_return(extractor)
      allow(extractor).to receive(:extract).and_return(true)
    end

    scenario 'users extract metadata from an fgdc metadata file' do
      visit polymorphic_path [:file_manager, resource]
      expect(page).to have_selector('form.extract_metadata button')
      click_button 'Extract'
      expect(page).to have_selector '.alert-success .text', text: 'Metadata is being extracted'
    end
  end
end
