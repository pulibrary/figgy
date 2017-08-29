# frozen_string_literal: true
require 'rails_helper'

RSpec.feature "File Manager" do
  let(:user) { FactoryGirl.create(:admin) }
  let(:file_set) { FactoryGirl.create_for_repository(:file_set) }
  let(:resource) do
    res = FactoryGirl.create_for_repository(:scanned_resource)
    res.member_ids = [file_set.id]
    adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
    adapter.persister.save(resource: res)
  end

  before do
    sign_in user
  end

  context 'without a derivative file' do
    let(:manifest_helper_class) { class_double(ManifestBuilder::ManifestHelper).as_stubbed_const(transfer_nested_constants: true) }
    let(:manifest_helper) { instance_double(ManifestBuilder::ManifestHelper) }
    before do
      allow(manifest_helper_class).to receive(:new).and_return(manifest_helper)
      allow(manifest_helper).to receive(:manifest_image_path).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
    end
    scenario 'visiting the file management interface' do
      visit polymorphic_path [:file_manager, resource]

      expect(page).to have_selector('.thumbnail span')
      expect(page).not_to have_selector('.thumbnail span.ignore-select')
    end
  end

  context 'with a derivative file' do
    let(:derivative_file) { instance_double(FileMetadata) }
    before do
      allow(file_set).to receive(:derivative_file).and_return(derivative_file)
    end
    scenario 'visiting the file management interface' do
      visit polymorphic_path [:file_manager, resource]

      expect(page).to have_selector('.thumbnail span')
      expect(page).to have_selector('.thumbnail span.ignore-select')
    end
  end
end
