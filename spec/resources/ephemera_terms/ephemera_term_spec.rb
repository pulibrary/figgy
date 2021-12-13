# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraTerm do
  describe "#linked_resource" do
    it "builds an object modeling the resource graph for ephemera terms" do
      resource = FactoryBot.create_for_repository(:ephemera_term)
      linked_ephemera_term = resource.linked_resource

      expect(linked_ephemera_term).to be_a LinkedData::LinkedEphemeraTerm
      expect(linked_ephemera_term.resource).to eq resource
    end
  end
end
