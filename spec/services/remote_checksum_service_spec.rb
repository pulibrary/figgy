# frozen_string_literal: true
require "rails_helper"

RSpec.describe RemoteChecksumService do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:logger) { Logger.new(nil) }
  let(:initial_rights) { RightsStatements.no_known_copyright }
  let(:new_rights) { RightsStatements.copyright_not_evaluated }
  let(:bad_rights) { RDF::URI("http://rightsstatements.org/vocab/BAD/1.0/") }

  describe ".remote"

  describe "#calculate" do
    it "delegates to the asynchronous job" do
      expect(RemoteChecksumJob).to have received(:perform_later).with("foo")
    end
  end
end
