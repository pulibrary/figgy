# frozen_string_literal: true
require "rails_helper"

RSpec.describe Nomisma do
  describe "#generate" do
    let(:output_path) { "tmp/princeton-nomisma-yyyy-mm-dd.rdf" }
    let(:generator) { described_class.new(output_path: output_path) }
    let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
    let(:coin_no_citation) { FactoryBot.create_for_repository(:coin, state: "complete") }
    let(:issue_no_citation) { FactoryBot.create_for_repository(:numismatic_issue, state: "complete", denomination: nil, member_ids: [coin_no_citation.id]) }
    let(:coin) { FactoryBot.create_for_repository(:coin, state: "complete", numismatic_citation: coin_citation) }
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, state: "complete", numismatic_citation: issue_citation, member_ids: [coin.id]) }

    before do
      issue
      coin
      issue_no_citation
      coin_no_citation
    end

    after do
      FileUtils.rm(output_path)
    end

    context "with an issue that both have reference URIs" do
      let(:issue_citation) { Numismatics::Citation.new(part: "1", number: "2", uri: "http://numismatics.org/1-2", numismatic_reference_id: reference.id) }
      let(:coin_citation) { Numismatics::Citation.new(part: "3", number: "4", uri: "http://numismatics.org/3-4", numismatic_reference_id: reference.id) }

      it "generates a nomisma rdf file with the issue URI" do
        generator.generate

        # Coin-1 with citation
        graph = RDF::Graph.load(output_path)
        values = graph.triples.select { |t| t[0].value == "https://catalog.princeton.edu/catalog/coin-1" }
                      .map { |t| { t[1].value => t[2].value } }
                      .reduce(:merge)

        expect(values["http://purl.org/dc/terms/title"]).to eq "40 nummi"
        expect(values["http://purl.org/dc/terms/identifier"]).to eq "coin-1"
        expect(values["http://nomisma.org/ontology#ObjectType"]).to eq "coin"
        expect(values["http://rdfs.org/ns/void#inDataset"]).to eq "https://catalog.princeton.edu/numismatics"
        expect(values["http://nomisma.org/ontology#hasAxis"]).to eq "300"
        expect(values["http://nomisma.org/ontology#hasMaterial"]).to eq "Bronze"
        expect(values["http://nomisma.org/ontology#hasTypeSeriesItem"]).to eq "http://numismatics.org/1-2"

        # Coin-2 wihtout citation and with alternate title
        values = graph.triples.select { |t| t[0].value == "https://catalog.princeton.edu/catalog/coin-2" }
                      .map { |t| { t[1].value => t[2].value } }
                      .reduce(:merge)

        expect(values["http://purl.org/dc/terms/title"]).to eq "Coin: 2"
        expect(values["http://nomisma.org/ontology#hasTypeSeriesItem"]).to be_nil
      end
    end

    context "with an issue that has no reference URI and a coin that has a refence URI" do
      let(:issue_citation) { Numismatics::Citation.new(part: "1", number: "2", numismatic_reference_id: reference.id) }
      let(:coin_citation) { Numismatics::Citation.new(part: "3", number: "4", uri: "http://numismatics.org/3-4", numismatic_reference_id: reference.id) }

      it "generates a nomisma rdf file with the coin URI" do
        generator.generate

        # Coin-1 with citation
        graph = RDF::Graph.load(output_path)
        values = graph.triples.select { |t| t[0].value == "https://catalog.princeton.edu/catalog/coin-1" }
                      .map { |t| { t[1].value => t[2].value } }
                      .reduce(:merge)

        expect(values["http://nomisma.org/ontology#hasTypeSeriesItem"]).to eq "http://numismatics.org/3-4"
      end
    end
  end
end
