# frozen_string_literal: true

class Nomisma
  class Void
    # @param url [String] URL of the most recent RDF document
    # @param date [ActiveSupport::TimeWithZone] created date of the most recent RDF document
    # @return [string] rdf+xml formatted VoID describing nomisma dataset
    def self.generate(url:, date:)
      new(url: url, date: date).generate
    end

    attr_reader :url, :date
    attr_accessor :graph
    def initialize(url:, date:)
      @url = url
      @date = date
      @graph = RDF::Graph.new
    end

    MAX_DEPTH = 1

    # Vocabulary
    VOID = RDF::Vocabulary.new("http://rdfs.org/ns/void#")
    DCTERMS = RDF::Vocab::DC

    # RDF document prefixes
    PREFIXES = {
      void: VOID.to_s,
      dcterms: DCTERMS.to_s,
      rdf: RDF.to_s
    }.freeze

    def generate
      dataset = RDF::URI.new(numismatics_collection_url)

      graph << RDF::Statement(dataset, RDF.type, VOID.Dataset)
      graph << RDF::Statement(dataset, DCTERMS.title, RDF::Literal.new(title))
      graph << RDF::Statement(dataset, DCTERMS.description, RDF::Literal.new(description))
      graph << RDF::Statement(dataset, DCTERMS.publisher, RDF::Literal.new(publisher))
      graph << RDF::Statement(dataset, DCTERMS.license, RDF::URI.new(license))
      graph << RDF::Statement(dataset, VOID.dataDump, RDF::URI.new(url))
      graph << RDF::Statement(dataset, DCTERMS.modified, RDF::Literal.new(modified, datatype: RDF::XSD.date))

      generate_xml
    end

    private

      def numismatics_collection_url
        "https://catalog.princeton.edu/numismatics"
      end

      def title
        "The Princeton University Numismatic Collection"
      end

      # rubocop:disable Metrics/LineLength
      def description
        "With about 125,000 coins, medals, tokens, decorations, and banknotes, the Princeton University Numismatic Collection (comprising the collections of Firestone Library, the Princeton University Art Museum, the Department of Near Eastern Studies, and the Antioch Excavation coin finds) ranks as one of the largest and most comprehensive academic numismatic collections in the world. It is open to the public by appointment with the curator. About ten percent of the collection has been digitized to date."
      end
      # rubocop:enable Metrics/LineLength

      def publisher
        "Princeton University Library"
      end

      def license
        "http://opendatacommons.org/licenses/odbl/"
      end

      def modified
        date.strftime("%F")
      end

      def generate_xml
        RDF::RDFXML::Writer.buffer(prefixes: PREFIXES, max_depth: MAX_DEPTH) do |writer|
          graph.each_statement do |statement|
            writer << statement
          end
        end
      end
  end
end
