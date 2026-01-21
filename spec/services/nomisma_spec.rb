require "rails_helper"

RSpec.describe Nomisma do
  describe "#generate" do
    let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
    let(:coin_no_citation) { FactoryBot.create_for_repository(:coin, state: "complete", identifier: "ark:/88435/testcoin2") }
    let(:issue_no_citation) { FactoryBot.create_for_repository(:numismatic_issue, state: "complete", denomination: nil, member_ids: [coin_no_citation.id]) }
    let(:issue_citation) { Numismatics::Citation.new(part: "1", number: "2", uri: "http://numismatics.org/1-2", numismatic_reference_id: reference.id) }
    let(:coin_citation) { Numismatics::Citation.new(part: "3", number: "4", uri: "http://numismatics.org/3-4", numismatic_reference_id: reference.id) }
    let(:coin) { FactoryBot.create_for_repository(:coin, state: "complete", identifier: "ark:/88435/testcoin", numismatic_citation: coin_citation) }
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, state: "complete", numismatic_citation: issue_citation, member_ids: [coin.id]) }

    context "with an issue and coin that both have reference URIs" do
      before do
        issue
        coin
        issue_no_citation
        coin_no_citation
      end

      it "generates a nomisma rdf file with URIs" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        # Coin-1 with citation
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values["http://purl.org/dc/terms/title"]).to eq "40 nummi. 1"
        expect(values["http://purl.org/dc/terms/identifier"]).to eq "coin-1"
        expect(values["http://nomisma.org/ontology#hasCollection"]).to eq "http://nomisma.org/id/princeton_university"
        expect(values["http://rdfs.org/ns/void#inDataset"]).to eq "https://catalog.princeton.edu/numismatics"
        expect(values["http://nomisma.org/ontology#hasAxis"]).to eq "300"
        expect(values["http://nomisma.org/ontology#hasTypeSeriesItem"]).to eq ["http://numismatics.org/1-2", "http://numismatics.org/3-4"]

        # Coins without citations are not included
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin2")
        expect(values).to be_nil
      end
    end

    context "with an issue that has no reference URI and a coin that has a refence URI" do
      let(:issue_citation) { Numismatics::Citation.new(part: "1", number: "2", numismatic_reference_id: reference.id) }

      before do
        issue
        coin
      end

      it "generates a nomisma rdf file with the coin URI" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        # Coin-1 with citation
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values["http://nomisma.org/ontology#hasTypeSeriesItem"]).to eq "http://numismatics.org/3-4"
      end
    end

    context "with a coin that doesn't have a numismatics.org URI in its citations" do
      before do
        issue
        coin
      end

      let(:issue_citation) { Numismatics::Citation.new(part: "1", number: "2", uri: "http://example.com/1-2", numismatic_reference_id: reference.id) }
      let(:coin_citation) { Numismatics::Citation.new(part: "3", number: "4", uri: "http://example.com/3-4", numismatic_reference_id: reference.id) }

      it "generates a nomisma rdf file without the coin" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values).to be_nil
      end
    end

    context "with a coin that has an Obverse and Reverse coin images" do
      let(:obverse) { FactoryBot.create_for_repository(:file_set, file_metadata: FileMetadata.new(original_filename: "coinO.jpg", use: PcdmUse::OriginalFile, mime_type: "image/tiff")) }
      let(:reverse) { FactoryBot.create_for_repository(:file_set, file_metadata: FileMetadata.new(original_filename: "coinR.jpg", use: PcdmUse::OriginalFile, mime_type: "image/tiff")) }
      let(:coin) { FactoryBot.create_for_repository(:coin, state: "complete", identifier: "ark:/88435/testcoin", numismatic_citation: coin_citation, member_ids: [obverse.id, reverse.id]) }

      before do
        issue
        coin
      end

      it "generates a nomisma rdf file with obverse and reverse description objects" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        ## Coin 1 main object
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values["http://nomisma.org/ontology#hasObverse"]).to eq "http://arks.princeton.edu/ark:/88435/testcoin#obverse"
        expect(values["http://nomisma.org/ontology#hasReverse"]).to eq "http://arks.princeton.edu/ark:/88435/testcoin#reverse"

        ## Coin 1 obverse image
        # Service
        values = select_triples(reader, "http://www.example.com/image-service/#{obverse.id}")
        expect(values["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]).to eq "http://rdfs.org/sioc/services#Service"
        expect(values["http://purl.org/dc/terms/conformsTo"]).to eq "http://iiif.io/api/image"
        expect(values["http://usefulinc.com/ns/doap#implements"]).to eq "http://iiif.io/api/image/2/level2.json"

        # Description
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin#obverse")
        expect(values["http://xmlns.com/foaf/0.1/depiction"]).to eq "http://www.example.com/image-service/#{obverse.id}/full/!400,400/0/default.jpg"
        expect(values["http://xmlns.com/foaf/0.1/thumbnail"]).to eq "http://www.example.com/image-service/#{obverse.id}/full/,120/0/default.jpg"

        ## Coin 1 reverse image
        # Service
        values = select_triples(reader, "http://www.example.com/image-service/#{reverse.id}")
        expect(values["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]).to eq "http://rdfs.org/sioc/services#Service"
        expect(values["http://purl.org/dc/terms/conformsTo"]).to eq "http://iiif.io/api/image"
        expect(values["http://usefulinc.com/ns/doap#implements"]).to eq "http://iiif.io/api/image/2/level2.json"

        # Description
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin#reverse")
        expect(values["http://xmlns.com/foaf/0.1/depiction"]).to eq "http://www.example.com/image-service/#{reverse.id}/full/!400,400/0/default.jpg"
        expect(values["http://xmlns.com/foaf/0.1/thumbnail"]).to eq "http://www.example.com/image-service/#{reverse.id}/full/,120/0/default.jpg"
      end
    end

    context "with a coin that has a Reverse coin image only" do
      let(:reverse) { FactoryBot.create_for_repository(:file_set, file_metadata: FileMetadata.new(original_filename: "coinR.jpg", use: PcdmUse::OriginalFile, mime_type: "image/tiff")) }
      let(:coin) { FactoryBot.create_for_repository(:coin, state: "complete", identifier: "ark:/88435/testcoin", numismatic_citation: coin_citation, member_ids: [reverse.id]) }

      before do
        issue
        coin
      end

      it "generates a nomisma rdf file with a reverse description object" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        ## Coin 1 main object
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values["http://nomisma.org/ontology#hasObverse"]).to be_nil
        expect(values["http://nomisma.org/ontology#hasReverse"]).to eq "http://arks.princeton.edu/ark:/88435/testcoin#reverse"

        ## Coin 1 obverse image
        # Description
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin#obverse")
        expect(values).to be_nil

        ## Coin 1 reverse image
        # Service
        values = select_triples(reader, "http://www.example.com/image-service/#{reverse.id}")
        expect(values.count).to eq 3

        # Description
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin#reverse")
        expect(values.count).to eq 2
      end
    end

    context "with a coin that has a no images" do
      before do
        issue
        coin
      end

      it "generates a nomisma rdf file with no thumbnails or description objects" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        ## Coin 1 main object
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values["http://nomisma.org/ontology#hasObverse"]).to be_nil
        expect(values["http://nomisma.org/ontology#hasReverse"]).to be_nil
        expect(values["http://xmlns.com/foaf/0.1/depiction"]).to be_nil
        expect(values["http://xmlns.com/foaf/0.1/thumbnail"]).to be_nil

        ## Coin 1 obverse image
        # Description
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin#obverse")
        expect(values).to be_nil

        ## Coin 1 reverse image
        # Description
        values = select_triples(reader, "https://catalog.princeton.edu/catalog/coin-2#obverse")
        expect(values).to be_nil
      end
    end

    context "with a coin in a non-complete state" do
      before do
        issue
        coin
        issue_no_citation
        coin_no_citation
      end

      let(:coin) { FactoryBot.create_for_repository(:coin, state: "pending", identifier: "ark:/88435/testcoin", numismatic_citation: coin_citation) }

      it "generates a nomisma rdf file without the coin" do
        document = described_class.generate
        reader = RDF::RDFXML::Reader.new(document)

        ## Coin 1 main object
        values = select_triples(reader, "http://arks.princeton.edu/ark:/88435/testcoin")
        expect(values).to be_nil
      end
    end

    context "with a coin that raises an error during processing" do
      before do
        issue
        coin
      end

      it "skips the coin and does not error during processing" do
        # Stub a coin decorator method that will raise an error
        decorator = instance_double(Numismatics::CoinDecorator, public_readable_state?: true, type_system_uris: ["http://numismatics.org/1-2"])
        allow(Numismatics::Coin).to receive(:new).and_return(coin)
        allow(coin).to receive(:decorate).and_return(decorator)
        allow(decorator).to receive(:obverse_file_set).and_raise("Error")

        expect { described_class.generate }.not_to raise_error
      end
    end
  end
end
