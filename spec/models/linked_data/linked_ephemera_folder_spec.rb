# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedEphemeraFolder do
  let(:linked_ephemera_folder) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term, label: "test term") }

  let(:ephemera_box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [resource.id]) }
  let(:ephemera_project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id]) }

  before do
    ephemera_box
    ephemera_project
  end

  it_behaves_like "LinkedData::Resource"

  describe "#geo_subject" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, geo_subject: [ephemera_term.id]) }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.geo_subject).not_to be_empty
        expect(linked_ephemera_folder.geo_subject.first).to eq(
          "@id" => "http://www.example.com/catalog/#{ephemera_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_term.label.first,
          "exact_match" => { "@id" => ephemera_term.uri.first }
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, geo_subject: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.geo_subject).not_to be_empty
        expect(linked_ephemera_folder.geo_subject.first).to eq "test value"
      end
    end
  end

  describe "#title" do
    context "when there's no transliterated title" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, title: ["Test Title"]) }
      it "provides an array" do
        expect(linked_ephemera_folder.as_jsonld["title"]).to eq ["Test Title"]
      end
    end

    context "when there's also a transliterated title" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, transliterated_title: ["Transliterated Title"], title: ["Test Title"]) }
      it "provides the transliaterated title as another title" do
        expect(linked_ephemera_folder.as_jsonld["title"]).to eq ["Test Title", "Transliterated Title"]
      end
    end
  end

  describe "#transliterated_title" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, transliterated_title: ["Test Title"]) }
    it "gets returned in as_jsonld" do
      expect(linked_ephemera_folder.as_jsonld["transliterated_title"]).to eq ["Test Title"]
    end
  end

  describe "#keywords" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, keywords: ["Tardis", "Sonic Screwdriver"]) }
    it "gets returned in as_jsonld" do
      expect(linked_ephemera_folder.as_jsonld["keywords"]).to eq ["Tardis", "Sonic Screwdriver"]
    end
  end

  describe "#genre" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, genre: ephemera_term.id) }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.as_jsonld["format"]).to eq(
          [{
            "@id" => "http://www.example.com/catalog/#{ephemera_term.id}",
            "@type" => "skos:Concept",
            "pref_label" => ephemera_term.label.first,
            "exact_match" => { "@id" => ephemera_term.uri.first }
          }]
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, genre: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.genre).to eq ["test value"]
      end
    end
  end

  describe "#geographic_origin" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, geographic_origin: ephemera_term.id) }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.geographic_origin).to eq(
          [{
            "@id" => "http://www.example.com/catalog/#{ephemera_term.id}",
            "@type" => "skos:Concept",
            "pref_label" => ephemera_term.label.first,
            "exact_match" => { "@id" => ephemera_term.uri.first }
          }]
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, geographic_origin: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.geographic_origin).to eq ["test value"]
      end
    end
  end

  describe "#language" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, language: [ephemera_term.id]) }

      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.language).not_to be_empty
        expect(linked_ephemera_folder.language.first).to eq(
          "@id" => "http://www.example.com/catalog/#{ephemera_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_term.label.first,
          "exact_match" => { "@id" => ephemera_term.uri.first }
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, language: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.language).not_to be_empty
        expect(linked_ephemera_folder.language.first).to eq "test value"
      end
    end
  end

  describe "#subject" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, subject: [ephemera_child_term.id]) }

      let(:parent_ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
      let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary, uri: "https://example.com/ns/testVocabulary", member_of_vocabulary_id: parent_ephemera_vocabulary.id) }
      let(:ephemera_child_term) { FactoryBot.create_for_repository(:ephemera_term, label: "test child term", member_of_vocabulary_id: ephemera_vocabulary.id, uri: nil) }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.subject).not_to be_empty
        expect(linked_ephemera_folder.subject.first).to eq(
          "@id" => "http://www.example.com/catalog/#{ephemera_child_term.id}",
          "@type" => "skos:Concept",
          "pref_label" => ephemera_child_term.label.first,
          "in_scheme" => {
            "@id" => "https://figgy.princeton.edu/ns/testVocabulary/testVocabulary",
            "@type" => "skos:ConceptScheme",
            "pref_label" => ephemera_vocabulary.label.first,
            "exact_match" => { "@id" => ephemera_vocabulary.uri.first }
          }
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, subject: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.subject).not_to be_empty
        expect(linked_ephemera_folder.subject.first).to eq "test value"
      end
    end
  end

  describe "#categories" do
    context "with Valkyrie::IDs for values" do
      let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary, uri: "https://example.com/ns/testVocabulary") }
      let(:ephemera_child_term) { FactoryBot.create_for_repository(:ephemera_term, label: "test child term", member_of_vocabulary_id: ephemera_vocabulary.id) }
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, subject: [ephemera_child_term.id]) }
      it "exposes the values as strings" do
        expect(linked_ephemera_folder.categories).not_to be_empty
        expect(linked_ephemera_folder.categories.first).to eq(
          "@id" => "http://www.example.com/catalog/#{ephemera_vocabulary.id}",
          "@type" => "skos:ConceptScheme",
          "pref_label" => ephemera_vocabulary.label.first,
          "exact_match" => { "@id" => ephemera_vocabulary.uri.first }
        )
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, subject: ["test value"]) }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.categories).to be_empty
      end
    end
  end

  describe "#source" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, source_url: "https://example.com/test-source") }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.source).not_to be_empty
        expect(linked_ephemera_folder.source.first).to eq("https://example.com/test-source")
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, source_url: "test value") }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.source).not_to be_empty
        expect(linked_ephemera_folder.source.first).to eq "test value"
      end
    end
  end

  describe "#related_url" do
    context "with Valkyrie::IDs for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, dspace_url: "http://dataspace.princeton.edu/jspui/handle/test") }
      it "exposes the values as JSON-LD Objects" do
        expect(linked_ephemera_folder.related_url).not_to be_empty
        expect(linked_ephemera_folder.related_url.first).to eq("http://dataspace.princeton.edu/jspui/handle/test")
      end
    end
    context "with strings for values" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, dspace_url: "test value") }
      it "exposes the values as JSON Strings" do
        expect(linked_ephemera_folder.related_url).not_to be_empty
        expect(linked_ephemera_folder.related_url.first).to eq "test value"
      end
    end
  end

  describe "#page_count" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, page_count: ["2", "3"]) }
    it "exposes the values as JSON Strings" do
      expect(linked_ephemera_folder.page_count).to be_a String
      expect(linked_ephemera_folder.page_count).to eq "2"
    end
  end

  describe "date_created and date_range" do
    let(:resource_factory) { :ephemera_folder }
    let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, date_created: "2012", date_range: [DateRange.new(start: "2013", end: "2017")]) }

    it_behaves_like "LinkedData::Resource::WithDateRange"

    it "exposes date_created values" do
      expect(linked_ephemera_folder.date_created.first).to eq "2012"
      linked_ephemera_folder.resource.id # ensures the resource id exists for an intermittent test failure on seed 7335
      expect(linked_ephemera_folder.as_jsonld["date_created"]).to eq linked_ephemera_folder.date_created
    end
  end

  describe "#as_jsonld" do
    let(:resource) do
      FactoryBot.create_for_repository(
        :ephemera_folder,
        barcode: "00000000000000",
        folder_number: "1",
        title: "test title",
        sort_title: "test title",
        alternative_title: ["test alternative title"],
        width: "test width",
        height: "test height",
        page_count: "test page count",
        series: "test series",
        provenance: "test provenance",
        creator: "test creator",
        contributor: ["test contributor"],
        publisher: ["test publisher"],
        description: "test description",
        date_created: "1970/01/01",
        source_url: "http://example.com",
        dspace_url: "http://example.com"
      )
    end

    it "exposes the attributes for serialization into JSON-LD" do
      jsonld = linked_ephemera_folder.as_jsonld
      expect(jsonld).not_to be_empty

      expect(jsonld["title"]).to eq ["test title"]
      expect(jsonld["barcode"]).to eq "00000000000000"
      expect(jsonld["folder_number"]).to eq "1"
      expect(jsonld["sort_title"]).to eq ["test title"]
      expect(jsonld["width"]).to eq ["test width cm"]
      expect(jsonld["height"]).to eq ["test height cm"]
      expect(jsonld["page_count"]).to eq "test page count"
      expect(jsonld["creator"]).to eq ["test creator"]
      expect(jsonld["contributor"]).to eq ["test contributor"]
      expect(jsonld["publisher"]).to eq ["test publisher"]
      expect(jsonld["description"]).to eq ["test description"]
      expect(jsonld["provenance"]).to eq "test provenance"

      project_json = jsonld["memberOf"].find { |x| x["title"] == ephemera_project.title.first }
      expect(project_json).not_to be_blank
    end

    context "with the title of a series specified" do
      it "exposes the attribute in JSON-LD", series: true do
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [resource.id])
        FactoryBot.create_for_repository(:ephemera_project, member_ids: [ephemera_box.id])

        expect(linked_ephemera_folder.as_jsonld).not_to be_empty
        expect(linked_ephemera_folder.as_jsonld["series"]).to eq "test series"
      end
    end

    context "when a member of a collection" do
      let(:resource) do
        FactoryBot.create_for_repository(
          :ephemera_folder,
          member_of_collection_ids: [collection.id]
        )
      end
      let(:collection) { FactoryBot.create_for_repository(:collection) }

      it "has memberOf for both the collection and the ephemera project" do
        jsonld = linked_ephemera_folder.as_jsonld

        expect(jsonld["member_of_collections"]).to be_nil
        collection_json = jsonld["memberOf"].find { |x| x["title"] == collection.title.first }
        expect(collection_json).to eq(
          "@id" => "http://www.example.com/catalog/#{collection.id}",
          "@type" => "pcdm:Collection",
          "title" => collection.title.first
        )

        project_json = jsonld["memberOf"].find { |x| x["title"] == ephemera_project.title.first }
        expect(project_json).not_to be_blank
      end
    end
  end
end
