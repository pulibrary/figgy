# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindEphemeraTermByLabel do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:term) { FactoryBot.create_for_repository(:ephemera_term, label: "Test", member_of_vocabulary_id: vocab.id) }
  let(:term2) { FactoryBot.create_for_repository(:ephemera_term, label: "Test", code: "t", member_of_vocabulary_id: vocab2.id) }
  let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
  let(:vocab2) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Test2") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_ephemera_term_by_label" do
    it "can find a term given a label" do
      output = query.find_ephemera_term_by_label(label: term.label)
      expect(output.id).to eq term.id
    end
    it "can restrict by a vocab" do
      term2
      output = query.find_ephemera_term_by_label(label: term.label, parent_vocab_label: vocab.label)
      expect(output.id).to eq term.id
    end
    it "can find by code" do
      term2
      output = query.find_ephemera_term_by_label(code: "t", parent_vocab_label: vocab2.label)
      expect(output.id).to eq term2.id
    end
    it "errors if neither label nor code is specified" do
      expect { query.find_ephemera_term_by_label }.to raise_error(ArgumentError)
    end
  end
end
