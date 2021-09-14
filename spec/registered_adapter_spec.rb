# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

##
# These tests just ensure all our registered adapters pass the shared specs.
RSpec.describe Valkyrie::MetadataAdapter do
  before do
    Valkyrie.logger.level = :error
  end
  after do
    Valkyrie.logger.level = :info
  end
  described_class.adapters.each do |key, adapter|
    # Skip bag adapter because the specs don't clean up after themselves and
    # it's tested in spec/adapters/bagit/metadata_adapter_spec.rb
    next if key == :bags
    if adapter.try(:write_only?)
      describe adapter do
        let(:adapter) { adapter }
        it_behaves_like "a write-only Valkyrie::MetadataAdapter"
      end
    else
      describe adapter do
        let(:adapter) { adapter }
        let(:persister) { adapter.persister }
        let(:query_service) { adapter.query_service }
        it_behaves_like "a Valkyrie::MetadataAdapter", adapter
        it_behaves_like "a Valkyrie::Persister"
        it_behaves_like "a Valkyrie query provider"
      end
    end
  end
end
