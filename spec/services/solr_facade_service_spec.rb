# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrFacadeService do
  let(:solr_facade_klass) { class_double(SolrFacadeService::SolrFacade).as_stubbed_const(transfer_nested_constants: true) }
  before do
    allow(solr_facade_klass).to receive(:new)
  end
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

  describe '.instance' do
    before do
      described_class.instance(repository: repository, query: query, current_page: 2, per_page: 11)
    end
    it 'builds a new SolrFacade Object' do
      expect(solr_facade_klass).to have_received(:new).with(
        repository: repository,
        query: query,
        current_page: 2,
        per_page: 11
      )
    end
  end
end
