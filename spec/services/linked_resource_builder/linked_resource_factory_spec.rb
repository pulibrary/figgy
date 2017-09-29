# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LinkedResourceBuilder::LinkedResourceFactory do
  describe '#new' do
    context 'with an ephemera folder' do
      let(:linked_ephemera_folder) { described_class.new(resource: resource) }
      let(:resource) { FactoryGirl.create_for_repository(:ephemera_folder) }

      it 'builds an object modeling the resource graph for ephemera folders' do
        expect(linked_ephemera_folder.new).to be_a LinkedResourceBuilder::LinkedEphemeraFolder
        expect(linked_ephemera_folder.new.resource).to eq resource
      end
    end

    context 'with an ephemera vocabulary' do
      let(:linked_ephemera_vocabulary) { described_class.new(resource: resource) }
      let(:resource) { FactoryGirl.create_for_repository(:ephemera_vocabulary) }

      it 'builds an object modeling the resource graph for ephemera vocabularies' do
        expect(linked_ephemera_vocabulary.new).to be_a LinkedResourceBuilder::LinkedEphemeraVocabulary
        expect(linked_ephemera_vocabulary.new.resource).to eq resource
      end
    end

    context 'with an ephemera term' do
      let(:linked_ephemera_term) { described_class.new(resource: resource) }
      let(:resource) { FactoryGirl.create_for_repository(:ephemera_term) }

      it 'builds an object modeling the resource graph for ephemera terms' do
        expect(linked_ephemera_term.new).to be_a LinkedResourceBuilder::LinkedEphemeraTerm
        expect(linked_ephemera_term.new.resource).to eq resource
      end
    end

    context 'with all other Valkyrie resources' do
      let(:linked_resource) { described_class.new(resource: resource) }
      let(:resource) { FactoryGirl.create_for_repository(:scanned_resource) }

      it 'builds an object modeling the resource graph generalizing all resources' do
        expect(linked_resource.new).to be_a LinkedResourceBuilder::LinkedResource
        expect(linked_resource.new.resource).to eq resource
      end
    end

    context 'with a Valkyrie resource which doesnt exist' do
      let(:linked_resource) { described_class.new(resource: resource) }
      let(:resource) { Valkyrie::ID.new('test') }

      it 'builds a literal for a nil Object' do
        expect(linked_resource.new).to be_a LinkedResourceBuilder::Literal
        expect(linked_resource.new.value).to eq nil
      end
    end
  end
end
