# frozen_string_literal: true

# Class for generating a nomisma RDF file from numismatics coins.
class Nomisma
  attr_reader :graph, :logger, :output_path
  def initialize(output_path: Rails.root.join("tmp", "princeton-nomisma.rdf"), logger: Logger.new(STDOUT))
    @graph = RDF::Graph.new
    @logger = logger
    @output_path = output_path
  end

  def generate
    counter = 0
    coins.each do |coin|
      counter += 1
      logger.info("Processing #{counter}/#{total_coins}: #{coin.title}")
      add_coin_to_graph(coin.decorate)
    end

    write_xml
  end

  private

    def coins
      query_service.find_all_of_model(model: Numismatics::Coin)
    end

    def total_coins
      @total_coins ||= query_service.count_all_of_model(model: Numismatics::Coin)
    end

    def add_coin_to_graph(coin)
      issue = coin.decorated_parent
      nmo = RDF::Vocabulary.new("http://nomisma.org/ontology#")
      void = RDF::Vocabulary.new("http://rdfs.org/ns/void#")
      dc = RDF::Vocab::DC
      coin_element = RDF::URI.new(catalog_link(coin))

      graph << RDF::Statement(coin_element, RDF.type, nmo.NumismaticObject)
      graph << RDF::Statement(coin_element, dc.title, RDF::Literal.new(title(coin)))
      graph << RDF::Statement(coin_element, dc.identifier, RDF::Literal.new(coin.orangelight_id))
      graph << RDF::Statement(coin_element, nmo.ObjectType, RDF::Literal.new("coin"))
      graph << RDF::Statement(coin_element, void.inDataset, RDF::URI.new(numismatics_collection_link))
      graph << RDF::Statement(coin_element, nmo.hasDiameter, RDF::Literal.new(coin.size, datatype: RDF::XSD.decimal)) if coin.size
      graph << RDF::Statement(coin_element, nmo.hasWeight, RDF::Literal.new(coin.weight, datatype: RDF::XSD.decimal)) if coin.weight
      graph << RDF::Statement(coin_element, nmo.hasAxis, RDF::Literal.new(coin.die_axis.first, datatype: RDF::XSD.decimal)) if coin.die_axis.present?
      graph << RDF::Statement(coin_element, nmo.hasMaterial, RDF::Literal.new(issue.metal.first)) if issue.metal.present?
      graph << RDF::Statement(coin_element, nmo.hasTypeSeriesItem, RDF::URI.new(coin.primary_reference_uri)) if coin.primary_reference_uri

      coin_element
    end

    def title(coin)
      coin.pub_created_display.presence || coin.title.first
    end

    def numismatics_collection_link
      "https://catalog.princeton.edu/numismatics"
    end

    def catalog_link(coin)
      "https://catalog.princeton.edu/catalog/#{coin.orangelight_id}"
    end

    def query_service
      @query_service ||= ChangeSetPersister.default.query_service
    end

    def write_xml
      RDF::RDFXML::Writer.open(output_path, prefixes: {
                                 nmo: "http://nomisma.org/ontology#",
                                 void: "http://rdfs.org/ns/void#",
                                 dc: "http://purl.org/dc/terms/"
                               }) do |writer|
        writer << graph
      end
    end
end
