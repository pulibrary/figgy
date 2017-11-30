# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrFacade do
  subject(:solr_facade) { described_class.new(repository: repository, query: query, current_page: 2, per_page: 11) }
  let(:repository) { instance_double(Blacklight::Solr::Repository) }
  let(:query) do
    {
      "facet.field" => ["member_of_collection_titles_ssim", "human_readable_type_ssim", "ephemera_project_ssim", "display_subject_ssim", "display_language_ssim", "state_ssim"],
      "facet.query" => [],
      "facet.pivot" => [],
      "fq" =>
        [
          "{!terms f=internal_resource_ssim}ScannedResource,Collection,EphemeraFolder,EphemeraBox,ScannedMap,VectorWork",
          "!member_of_ssim:['' TO *]",
          "member_of_collection_ids_ssim:id-test"
        ],
      "hl.fl" => [],
      "qf" => ["identifier_tesim", "title_ssim", "title_tesim", "source_metadata_identifier_ssim", "local_identifier_ssim", "barcode_ssim"],
      "qt" => "search",
      "rows" => 10,
      "facet" => true,
      "sort" => "score desc, updated_at_dtsi desc"
    }
  end
  let(:response) { instance_double(Blacklight::Solr::Response) }
  let(:response_documents) { [instance_double(SolrDocument)] }

  describe '#query_response' do
    before do
      allow(repository).to receive(:search).and_return(response)
    end
    it 'queries the Solr Index' do
      expect(solr_facade.query_response).to eq response
      expect(repository).to have_received(:search).with(query)
    end
  end

  describe '#members' do
    before do
      allow(response).to receive(:documents).and_return(response_documents)
      allow(repository).to receive(:search).and_return(response)
    end
    it 'queries the Solr Index' do
      expect(solr_facade.members).to eq response_documents
    end
  end
end
