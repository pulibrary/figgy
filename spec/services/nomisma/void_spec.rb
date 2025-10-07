# frozen_string_literal: true
require "rails_helper"

RSpec.describe Nomisma::Void do
  describe "#generate" do
    it "generates a void rdf document" do
      url = "https://figgy.princeton.edu/nomisma/1.rdf"
      date = Time.zone.parse("2025-10-08 18:19:40 UTC")
      document = described_class.generate(url: url, date: date)
      reader = RDF::RDFXML::Reader.new(document)
      values = select_triples(reader, "https://catalog.princeton.edu/numismatics")

      expect(values["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]).to eq "http://rdfs.org/ns/void#Dataset"
      expect(values["http://purl.org/dc/terms/title"]).to eq "The Princeton University Numismatic Collection"
      expect(values["http://purl.org/dc/terms/description"]).to include "With about 125,000 coins, medals, tokens"
      expect(values["http://purl.org/dc/terms/publisher"]).to eq "Princeton University Library"
      expect(values["http://purl.org/dc/terms/license"]).to eq "http://opendatacommons.org/licenses/odbl/"
      expect(values["http://rdfs.org/ns/void#dataDump"]).to eq url
      expect(values["http://purl.org/dc/terms/modified"]).to eq "2025-10-08"
    end
  end
end
