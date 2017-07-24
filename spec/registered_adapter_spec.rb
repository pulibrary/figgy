# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

##
# These tests just ensure all our registered adapters pass the shared specs.
RSpec.describe Valkyrie::MetadataAdapter do
  described_class.adapters.each do |_key, adapter|
    let(:adapter) { adapter }
    let(:persister) { adapter.persister }
    let(:query_service) { adapter.query_service }
    it_behaves_like "a Valkyrie::MetadataAdapter", adapter
    it_behaves_like "a Valkyrie::Persister"
    it_behaves_like "a Valkyrie query provider"
  end
end
