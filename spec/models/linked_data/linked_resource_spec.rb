# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedResource do
  describe ".for" do
    context "with an ephemera folder" do
      let(:linked_ephemera_folder) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }

      it "builds an object modeling the resource graph for ephemera folders" do
        expect(linked_ephemera_folder).to be_a LinkedData::LinkedEphemeraFolder
        expect(linked_ephemera_folder.resource).to eq resource
      end
    end

    context "with an ephemera vocabulary" do
      let(:linked_ephemera_vocabulary) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_vocabulary) }

      it "builds an object modeling the resource graph for ephemera vocabularies" do
        expect(linked_ephemera_vocabulary).to be_a LinkedData::LinkedEphemeraVocabulary
        expect(linked_ephemera_vocabulary.resource).to eq resource
      end
    end

    context "with an ephemera term" do
      let(:linked_ephemera_term) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_term) }

      it "builds an object modeling the resource graph for ephemera terms" do
        expect(linked_ephemera_term).to be_a LinkedData::LinkedEphemeraTerm
        expect(linked_ephemera_term.resource).to eq resource
      end
    end

    context "with a scanned resource" do
      let(:linked_resource) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }

      it "builds an object modeling the resource graph generalizing all resources" do
        expect(linked_resource).to be_a LinkedData::LinkedImportedResource
        expect(linked_resource.resource).to eq resource
      end
    end

    context "with a VectorResource" do
      let(:linked_resource) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:vector_resource) }

      it "builds an object modeling the resource graph generalizing all resources" do
        expect(linked_resource).to be_a LinkedData::LinkedImportedResource
        expect(linked_resource.resource).to eq resource
      end
    end

    context "with a ScannedMap" do
      let(:linked_resource) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:scanned_map) }

      it "builds an object modeling the resource graph generalizing all resources" do
        expect(linked_resource).to be_a LinkedData::LinkedImportedResource
        expect(linked_resource.resource).to eq resource
      end
    end

    context "with a Raster Resource" do
      let(:linked_resource) { described_class.for(resource: resource) }
      let(:resource) { FactoryBot.create_for_repository(:raster_resource) }

      it "builds an object modeling the resource graph generalizing all resources" do
        expect(linked_resource).to be_a LinkedData::LinkedImportedResource
        expect(linked_resource.resource).to eq resource
      end
    end

    context "with a Valkyrie resource which doesnt exist" do
      let(:linked_resource) { described_class.for(resource: resource) }
      let(:resource) { Valkyrie::ID.new("test") }

      it "builds a literal for a nil Object" do
        expect(linked_resource).to be_a LinkedData::Literal
        expect(linked_resource.value).to eq nil
      end
    end
  end
end
