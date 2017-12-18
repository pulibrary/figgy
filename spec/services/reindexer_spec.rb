# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Reindexer do
  let(:solr_adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:postgres_adapter) { Valkyrie::MetadataAdapter.find(:postgres) }
  let(:logger) { instance_double('Logger').as_null_object }

  before do
    Valkyrie.logger.level = Logger::ERROR
  end

  describe ".reindex_all" do
    context "when there are records not in solr" do
      it "puts them in solr" do
        resource = FactoryBot.build(:scanned_resource)
        output = postgres_adapter.persister.save(resource: resource)
        expect { solr_adapter.query_service.find_by(id: output.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError

        described_class.reindex_all(logger: logger)

        expect { solr_adapter.query_service.find_by(id: output.id) }.not_to raise_error
      end
    end
    context "when there are records in solr which are no longer in postgres" do
      it "gets rid of them" do
        resource = FactoryBot.build(:scanned_resource)
        output = solr_adapter.persister.save(resource: resource)

        described_class.reindex_all(logger: logger)

        expect { solr_adapter.query_service.find_by(id: output.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
