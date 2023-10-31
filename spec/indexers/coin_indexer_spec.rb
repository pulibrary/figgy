# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe CoinIndexer do
  it_behaves_like "a Valkyrie::Persistence::Solr::Indexer"
  describe "#to_solr" do
    context "when given a not-coin" do
      it "returns an empty hash" do
        indexer = described_class.new(resource: ScannedResource.new)

        expect(indexer.to_solr).to eq({})
      end
    end
    context "when given a resource without parents" do
      it "returns an empty hash" do
        coin = FactoryBot.create_for_repository(:coin)
        indexer = described_class.new(resource: coin)

        expect(indexer.to_solr).to eq({})
      end
    end
    context "when given a coin with an issue" do
      it "returns issue properties and linked coin properties" do
        person = FactoryBot.create_for_repository(:numismatic_person)
        reference = FactoryBot.create_for_repository(:numismatic_reference, author_id: person.id)
        numismatic_artist = Numismatics::Artist.new(person_id: person.id, signature: "artist signature", role: "artist role", side: "artist side")
        numismatic_subject = Numismatics::Subject.new(type: "Other Person", subject: "Athena")
        numismatic_attribute = Numismatics::Attribute.new(description: "attribute description", name: "attribute name")
        numismatic_citation = Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: reference.id)
        numismatic_monogram1 = FactoryBot.create_for_repository(:numismatic_monogram, title: "Alexander", thumbnail_id: "alexander-url")
        numismatic_accession = FactoryBot.create_for_repository(:numismatic_accession, date: "1939-01-01T00:00:00.000Z", person_id: person.id)
        numismatic_place = FactoryBot.create_for_repository(:numismatic_place)
        numismatic_person = FactoryBot.create_for_repository(:numismatic_person)
        numismatic_provenance = Numismatics::Provenance.new(person_id: person.id, note: "note", date: "12/04/1999")
        coin = FactoryBot.create_for_repository(:coin,
                                                find_place_id: numismatic_place.id,
                                                numismatic_accession_id: numismatic_accession.id,
                                                numismatic_citation: numismatic_citation,
                                                provenance: numismatic_provenance)
        FactoryBot.create_for_repository(:numismatic_issue,
                                                 member_ids: [coin.id],
                                                 numismatic_artist: numismatic_artist,
                                                 numismatic_citation: numismatic_citation,
                                                 numismatic_subject: numismatic_subject,
                                                 numismatic_place_id: numismatic_place.id,
                                                 obverse_attribute: numismatic_attribute,
                                                 reverse_attribute: numismatic_attribute,
                                                 ruler_id: numismatic_person.id,
                                                 master_id: numismatic_person.id,
                                                 numismatic_monogram_ids: [numismatic_monogram1.id])
        indexer = described_class.new(resource: coin)

        expect(indexer.to_solr).to eq(
          "accession_tesim" => ["1: 1939-01-01T00:00:00+00:00 gift name1 name2 ($99.00)"],
          "citation_tesim" => ["short-title, name1 name2, Test Reference, 2001 citation part citation number"],
          "find_place_tesim" => ["city, state, region"],
          "provenance_tesim" => ["name1 name2; 12/04/1999; note"],
          "issue_numismatic_monogram_ids_tesim" => [numismatic_monogram1.id.to_s],
          "issue_numismatic_place_id_tesim" => [numismatic_place.id.to_s],
          "issue_ruler_id_tesim" => [numismatic_person.id.to_s],
          "issue_master_id_tesim" => [numismatic_person.id.to_s],
          "issue_obverse_attribute_tesim" => ["attribute name, attribute description"],
          "issue_reverse_attribute_tesim" => ["attribute name, attribute description"],
          "issue_denomination_tesim" => ["$1"],
          "issue_issue_number_tesim" => ["1"],
          "issue_rights_statement_tesim" => ["http://rightsstatements.org/vocab/NKC/1.0/"],
          "issue_downloadable_tesim" => ["public"],
          "issue_artist_tesim" => ["name1 name2, artist signature"],
          "issue_citation_tesim" => ["short-title, name1 name2, Test Reference, 2001 citation part citation number"],
          "issue_subject_tesim" => ["Other Person, Athena"],
          "issue_place_tesim" => ["city, state, region"],
          "issue_ruler_tesim" => ["name1 name2 epithet (1868 to 1963)"],
          "issue_master_tesim" => ["name1 name2 epithet (1868 to 1963)"],
          "issue_monograms_tesim" => ["Alexander"]
        )
      end
    end
  end
end
