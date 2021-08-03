# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateFgdcOnlinkJob do
  with_queue_adapter :inline

  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:parent_resource) do
    change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [fgdc_file], member_ids: [vector_file_set.id]))
  end
  let(:fgdc_file) { fixture_file_upload("files/geo_metadata/fgdc-no-onlink.xml", "application/xml") }
  let(:fgdc_file_set) { Wayfinder.for(parent_resource).geo_metadata_members.first }
  let(:vector_file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: vector_file_metadata) }
  let(:vector_file_id) { "1234567" }
  let(:vector_file_metadata) do
    FileMetadata.new(
      id: Valkyrie::ID.new(vector_file_id),
      use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
      mime_type: 'application/zip; ogr-format="ESRI Shapefile"'
    )
  end
  # Shared output context for stubbing tika
  let(:tika_output) { tika_xml_output }

  before do
    allow(CheckFixityJob).to receive(:set).and_return(CheckFixityJob)
    allow(CheckFixityJob).to receive(:perform_later)
  end

  describe "#perform_now" do
    let(:saved_file) { storage_adapter.find_by(id: fgdc_file_set.original_file.file_identifiers[0]) }
    let(:doc) { Nokogiri::XML(saved_file.read) }

    it "inserts the vector file download url into the FGDC onlink element and updates checksum" do
      # Save checksum of fgdc file before running job
      parent_decorator = parent_resource.decorate
      initial_fgdc = parent_decorator.geo_metadata_members[0]
      initial_checksum = initial_fgdc.original_file.checksum[0]

      described_class.perform_now(parent_resource.id.to_s)
      expect(doc.at_xpath("//idinfo/citation/citeinfo/onlink").text).to match(/#{vector_file_set.id}\/file\/#{vector_file_id}/)
      expect(fgdc_file_set.original_file.checksum[0]).not_to eq(initial_checksum)
    end
  end
end
