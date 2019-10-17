# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedResourceFactory do
  describe "#new" do
    context "with an ephemera folder" do
      let(:linked_ephemera_folder) { described_class.new(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }

      it "builds an object modeling the resource graph for ephemera folders" do
        expect(linked_ephemera_folder.new).to be_a LinkedData::LinkedEphemeraFolder
        expect(linked_ephemera_folder.new.resource).to eq resource
      end
    end

    context "with an ephemera vocabulary" do
      let(:linked_ephemera_vocabulary) { described_class.new(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_vocabulary) }

      it "builds an object modeling the resource graph for ephemera vocabularies" do
        expect(linked_ephemera_vocabulary.new).to be_a LinkedData::LinkedEphemeraVocabulary
        expect(linked_ephemera_vocabulary.new.resource).to eq resource
      end
    end

    context "with an ephemera term" do
      let(:linked_ephemera_term) { described_class.new(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_term) }

      it "builds an object modeling the resource graph for ephemera terms" do
        expect(linked_ephemera_term.new).to be_a LinkedData::LinkedEphemeraTerm
        expect(linked_ephemera_term.new.resource).to eq resource
      end
    end

    context "with all other Valkyrie resources" do
      let(:linked_resource) { described_class.new(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }

      it "builds an object modeling the resource graph generalizing all resources" do
        expect(linked_resource.new).to be_a LinkedData::LinkedResource
        expect(linked_resource.new.resource).to eq resource
      end
    end

    context "with a scanned resource" do
      let(:linked_resource) { described_class.new(resource: resource).new }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, title: ["more", "than", "one", "title"]) }
      it "returns an array of titles" do
        expect(linked_resource.as_jsonld["title"]).to be_a Array
      end

      it "returns JSON-LD with a system_created_at/system_updated_at date" do
        expect(linked_resource.as_jsonld["system_created_at"]).to be_present
        expect(linked_resource.as_jsonld["system_updated_at"]).to be_present
      end
    end

    context "with a Valkyrie resource which doesnt exist" do
      let(:linked_resource) { described_class.new(resource: resource) }
      let(:resource) { Valkyrie::ID.new("test") }

      it "builds a literal for a nil Object" do
        expect(linked_resource.new).to be_a LinkedData::Literal
        expect(linked_resource.new.value).to eq nil
      end
    end
  end
end
