# frozen_string_literal: true
require 'rails_helper'

RSpec.describe QueryAdapter do
  subject(:query_adapter) { described_class.new(query_service: query_service, model: EphemeraVocabulary) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#all" do
    let(:term) { FactoryGirl.create_for_repository(:ephemera_term) }
    let(:vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }
    before do
      FactoryGirl.create_for_repository(:ephemera_vocabulary)
      FactoryGirl.create_for_repository(:ephemera_vocabulary)
    end
    it "retrieves all resources using the query service" do
      expect(query_adapter.all).not_to be_empty
      expect(query_adapter.all.first).to be_a EphemeraVocabularyDecorator
      expect(query_adapter.all.last).to be_a EphemeraVocabularyDecorator
    end
  end
end
