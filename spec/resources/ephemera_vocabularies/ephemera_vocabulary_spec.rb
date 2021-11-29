# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraVocabulary do
  describe "#linked_resource" do
    it "builds an object modeling the resource graph for ephemera vocabularies" do
      resource = FactoryBot.create_for_repository(:ephemera_vocabulary)
      linked_ephemera_vocabulary = resource.linked_resource

      expect(linked_ephemera_vocabulary).to be_a LinkedData::LinkedEphemeraVocabulary
      expect(linked_ephemera_vocabulary.resource).to eq resource
    end
  end
end
