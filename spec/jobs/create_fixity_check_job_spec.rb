# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe CreateFixityCheckJob do
  let(:file) { fixture_file_upload('files/color-landscape.tif', 'image/tiff') }
  let(:file_set_id) { resource.member_ids.first.id }
  let(:resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      files: [file]
    )
  end

  before do
    GenerateChecksumJob.perform_now(file_set_id)
  end

  it 'creates a fixity check object for a fileset' do
    described_class.perform_now(file_set_id)
    fc = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_all_of_model(model: FixityCheck)
    expect(fc.to_a.size).to eq 1
    expect(fc.first.file_set_id).to eq file_set_id
    expect(fc.first.success).to eq 1
  end

  xit "doesn't save in solr, just postgres" do
  end
end
