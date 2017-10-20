# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LinkedData::LinkedEphemeraFolder do
  subject(:linked_ephemera_folder) { described_class.new(resource: ephemera_folder) }
  let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder) }
  let(:ephemera_term) { FactoryGirl.create_for_repository(:ephemera_term, label: 'test term') }

  describe '#geo_subject' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, geo_subject: [ephemera_term.id]) }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.geo_subject).not_to be_empty
        expect(linked_ephemera_folder.geo_subject.first).to eq(
          "@id" => "http://www.example.com/concern/ephemera_terms/#{ephemera_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_term.label,
          "exact_match" => { "@id" => ephemera_term.uri.first }
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, geo_subject: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.geo_subject).not_to be_empty
        expect(linked_ephemera_folder.geo_subject.first).to eq 'test value'
      end
    end
  end

  describe '#genre' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, genre: ephemera_term.id) }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.genre).to eq(
          [{
            "@id" => "http://www.example.com/concern/ephemera_terms/#{ephemera_term.id}",
            "@type" => "skos:Concept",
            "pref_label" => ephemera_term.label,
            "exact_match" => { "@id" => ephemera_term.uri.first }
          }]
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, genre: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.genre).to eq ['test value']
      end
    end
  end

  describe '#geographic_origin' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, geographic_origin: ephemera_term.id) }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.geographic_origin).to eq(
          [{
            "@id" => "http://www.example.com/concern/ephemera_terms/#{ephemera_term.id}",
            "@type" => "skos:Concept",
            "pref_label" => ephemera_term.label,
            "exact_match" => { "@id" => ephemera_term.uri.first }
          }]
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, geographic_origin: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.geographic_origin).to eq ['test value']
      end
    end
  end

  describe '#language' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, language: [ephemera_term.id]) }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.language).not_to be_empty
        expect(linked_ephemera_folder.language.first).to eq(
          "@id" => "http://www.example.com/concern/ephemera_terms/#{ephemera_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_term.label,
          "exact_match" => { "@id" => ephemera_term.uri.first }
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, language: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.language).not_to be_empty
        expect(linked_ephemera_folder.language.first).to eq 'test value'
      end
    end
  end

  describe '#subject' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, subject: [ephemera_child_term.id]) }
      let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary, uri: 'https://example.com/ns/testVocabulary') }
      let(:ephemera_child_term) { FactoryGirl.create_for_repository(:ephemera_term, label: 'test child term', member_of_vocabulary_id: ephemera_vocabulary.id) }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.subject).not_to be_empty
        expect(linked_ephemera_folder.subject.first).to eq(
          "@id" => "http://www.example.com/concern/ephemera_terms/#{ephemera_child_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_child_term.label,
          "exact_match" => { "@id" => ephemera_child_term.uri.first },
          "in_scheme" => {
            "@id" => "http://www.example.com/concern/ephemera_vocabularies/#{ephemera_vocabulary.id}",
            "@type" => "skos:Concept",
            "pref_label" => ephemera_vocabulary.label,
            "exact_match" => { "@id" => ephemera_vocabulary.uri.first }
          }
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, subject: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.subject).not_to be_empty
        expect(linked_ephemera_folder.subject.first).to eq 'test value'
      end
    end
  end

  describe '#categories' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_vocabulary) { FactoryGirl.create_for_repository(:ephemera_vocabulary, uri: 'https://example.com/ns/testVocabulary') }
      let(:ephemera_child_term) { FactoryGirl.create_for_repository(:ephemera_term, label: 'test child term', member_of_vocabulary_id: ephemera_vocabulary.id) }
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, subject: [ephemera_child_term.id]) }
      it 'exposes the values as strings' do
        expect(linked_ephemera_folder.categories).not_to be_empty
        expect(linked_ephemera_folder.categories.first).to eq(
          "@id" => "http://www.example.com/concern/ephemera_vocabularies/#{ephemera_vocabulary.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_vocabulary.label,
          "exact_match" => { "@id" => ephemera_vocabulary.uri.first }
        )
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, subject: ["test value"]) }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.categories).to be_empty
      end
    end
  end

  describe '#source' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, source_url: 'https://example.com/test-source') }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.source).not_to be_empty
        expect(linked_ephemera_folder.source.first).to eq('https://example.com/test-source')
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, source_url: "test value") }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.source).not_to be_empty
        expect(linked_ephemera_folder.source.first).to eq 'test value'
      end
    end
  end

  describe '#related_url' do
    context 'with Valkyrie::IDs for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, dspace_url: 'http://dataspace.princeton.edu/jspui/handle/test') }
      it 'exposes the values as JSON-LD Objects' do
        expect(linked_ephemera_folder.related_url).not_to be_empty
        expect(linked_ephemera_folder.related_url.first).to eq('http://dataspace.princeton.edu/jspui/handle/test')
      end
    end
    context 'with strings for values' do
      let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, dspace_url: "test value") }
      it 'exposes the values as JSON Strings' do
        expect(linked_ephemera_folder.related_url).not_to be_empty
        expect(linked_ephemera_folder.related_url.first).to eq 'test value'
      end
    end
  end

  describe '#page_count' do
    let(:ephemera_folder) { FactoryGirl.create_for_repository(:ephemera_folder, page_count: ["2", "3"]) }
    it 'exposes the values as JSON Strings' do
      expect(linked_ephemera_folder.page_count).to be_a String
      expect(linked_ephemera_folder.page_count).to eq '2'
    end
  end

  describe '#local_fields' do
    let(:ephemera_folder) do
      FactoryGirl.create_for_repository(
        :ephemera_folder,
        barcode: '00000000000000',
        folder_number: '1',
        title: 'test title',
        sort_title: 'test title',
        alternative_title: ['test alternative title'],
        width: 'test width',
        height: 'test height',
        page_count: 'test page count',
        series: 'test series',
        creator: 'test creator',
        contributor: ['test contributor'],
        publisher: ['test publisher'],
        description: 'test description',
        date_created: '1970/01/01',
        source_url: 'http://example.com',
        dspace_url: 'http://example.com'
      )
    end

    it 'exposes the attributes for serialization into JSON-LD' do
      ephemera_box = FactoryGirl.create_for_repository(:ephemera_box, member_ids: [ephemera_folder.id])
      FactoryGirl.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

      expect(linked_ephemera_folder.local_fields).not_to be_empty

      expect(linked_ephemera_folder.local_fields[:barcode]).to eq "00000000000000"
      expect(linked_ephemera_folder.local_fields[:folder_number]).to eq "1"
      expect(linked_ephemera_folder.local_fields[:sort_title]).to eq ["test title"]
      expect(linked_ephemera_folder.local_fields[:width]).to eq ["test width"]
      expect(linked_ephemera_folder.local_fields[:height]).to eq ["test height"]
      expect(linked_ephemera_folder.local_fields[:page_count]).to eq "test page count"
      expect(linked_ephemera_folder.local_fields[:creator]).to eq ["test creator"]
      expect(linked_ephemera_folder.local_fields[:contributor]).to eq ['test contributor']
      expect(linked_ephemera_folder.local_fields[:publisher]).to eq ['test publisher']
      expect(linked_ephemera_folder.local_fields[:description]).to eq ["test description"]
    end
  end
end
