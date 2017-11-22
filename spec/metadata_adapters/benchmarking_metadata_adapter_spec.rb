# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe BenchmarkingMetadataAdapter do
  let(:adapter) { described_class.new(Valkyrie::MetadataAdapter.find(:index_solr)) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  it_behaves_like "a Valkyrie::MetadataAdapter"
  it_behaves_like "a Valkyrie::Persister"
  it_behaves_like "a Valkyrie query provider"
end
