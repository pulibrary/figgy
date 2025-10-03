# frozen_string_literal: true

# Class for generating a nomisma RDF file from numismatics coins.
class Nomisma
  attr_reader :graph, :logger, :output_path
  def initialize(output_path: Rails.root.join("tmp", "princeton-nomisma.rdf"), logger: Logger.new(STDOUT))
    @graph = RDF::Graph.new
    @logger = logger
    @output_path = output_path
  end

  MAX_DEPTH = 1

  # Vocabulary
  NMO = RDF::Vocabulary.new("http://nomisma.org/ontology#")
  VOID = RDF::Vocabulary.new("http://rdfs.org/ns/void#")
  DCTERMS = RDF::Vocab::DC
  FOAF = RDF::Vocab::FOAF
  EDM = RDF::Vocab::EDM
  SVCS = RDF::Vocabulary.new("http://rdfs.org/sioc/services#")
  DOAP = RDF::Vocab::DOAP

  def generate
    counter = 0
    coins.each do |coin|
      decorated_coin = coin.decorate
      next unless decorated_coin.public_readable_state?
      counter += 1
      logger.info("Processing #{counter}/#{total_coins}: #{coin.title}")
      add_coin_to_graph(decorated_coin)
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

      coin_element = coin_element(coin: coin)
      coin_obverse = coin_element(coin: coin, side: "obverse")
      coin_reverse = coin_element(coin: coin, side: "reverse")

      graph << RDF::Statement(coin_element, RDF.type, NMO.NumismaticObject)
      graph << RDF::Statement(coin_element, DCTERMS.title, RDF::Literal.new(title(coin)))
      graph << RDF::Statement(coin_element, DCTERMS.identifier, RDF::Literal.new(coin.orangelight_id))
      graph << RDF::Statement(coin_element, NMO.ObjectType, RDF::Literal.new("coin"))
      graph << RDF::Statement(coin_element, VOID.inDataset, RDF::URI.new(numismatics_collection_link))
      graph << RDF::Statement(coin_element, NMO.hasDiameter, RDF::Literal.new(coin.size, datatype: RDF::XSD.decimal)) if coin.size
      graph << RDF::Statement(coin_element, NMO.hasWeight, RDF::Literal.new(coin.weight, datatype: RDF::XSD.decimal)) if coin.weight
      graph << RDF::Statement(coin_element, NMO.hasAxis, RDF::Literal.new(coin.die_axis.first, datatype: RDF::XSD.decimal)) if coin.die_axis.present?
      graph << RDF::Statement(coin_element, NMO.hasMaterial, RDF::Literal.new(issue.metal.first)) if issue.metal.present?
      graph << RDF::Statement(coin_element, NMO.hasObverse, RDF::URI.new(coin_obverse.to_s)) if coin_obverse
      graph << RDF::Statement(coin_element, NMO.hasReverse, RDF::URI.new(coin_reverse.to_s)) if coin_reverse

      # Add reference URIs as TypeSeriesItems
      coin.reference_uris.each do |uri|
        graph << RDF::Statement(coin_element, NMO.hasTypeSeriesItem, RDF::URI.new(uri))
      end

      if coin_obverse
        graph << RDF::Statement(coin_obverse, RDF.type, RDF.Description)
        graph << RDF::Statement(coin_obverse, FOAF.depiction, RDF::URI.new(depiction_uri(coin: coin, side: "obverse")))
        graph << RDF::Statement(coin_obverse, FOAF.thumbnail, RDF::URI.new(thumbnail_uri(coin: coin, side: "obverse")))

        # add IIIF service object
        service_element = RDF::URI.new(iiif_base_path(coin: coin, side: "obverse"))
        graph << RDF::Statement(service_element, RDF.type, SVCS.Service)
        graph << RDF::Statement(service_element, DCTERMS.conformsTo, RDF::URI.new("http://iiif.io/api/image"))
        graph << RDF::Statement(service_element, DOAP.implements, RDF::URI.new("http://iiif.io/api/image/2/level2.json"))

        # add IIIF service to Europeana WebResource object
        primary_side_element = RDF::URI.new(depiction_uri(coin: coin, side: "obverse"))
        graph << RDF::Statement(primary_side_element, RDF.type, EDM.WebResource)
        graph << RDF::Statement(primary_side_element, SVCS.has_service, service_element)
        graph << RDF::Statement(primary_side_element, DCTERMS.isReferencedBy, RDF::URI.new(iiif_base_path(coin: coin, side: "obverse") + "/info.json"))
      end

      if coin_reverse
        graph << RDF::Statement(coin_reverse, RDF.type, RDF.Description)
        graph << RDF::Statement(coin_reverse, FOAF.depiction, RDF::URI.new(depiction_uri(coin: coin, side: "reverse")))
        graph << RDF::Statement(coin_reverse, FOAF.thumbnail, RDF::URI.new(thumbnail_uri(coin: coin, side: "reverse")))

        # add IIIF service object
        service_element = RDF::URI.new(iiif_base_path(coin: coin, side: "reverse"))
        graph << RDF::Statement(service_element, RDF.type, SVCS.Service)
        graph << RDF::Statement(service_element, DCTERMS.conformsTo, RDF::URI.new("http://iiif.io/api/image"))
        graph << RDF::Statement(service_element, DOAP.implements, RDF::URI.new("http://iiif.io/api/image/2/level2.json"))

        # add IIIF service to Europeana WebResource object
        primary_side_element = RDF::URI.new(depiction_uri(coin: coin, side: "reverse"))
        graph << RDF::Statement(primary_side_element, RDF.type, EDM.WebResource)
        graph << RDF::Statement(primary_side_element, SVCS.has_service, service_element)
        graph << RDF::Statement(primary_side_element, DCTERMS.isReferencedBy, RDF::URI.new(iiif_base_path(coin: coin, side: "reverse") + "/info.json"))
      end

      coin_element
    end

    def coin_element(coin:, side: nil)
      if side == "obverse"
        return nil unless coin.obverse_file_set
        RDF::URI.new(ark_link(coin) + "#obverse")
      elsif side == "reverse"
        return nil unless coin.reverse_file_set
        RDF::URI.new(ark_link(coin) + "#reverse")
      else
        RDF::URI.new(ark_link(coin))
      end
    end

    def depiction_uri(coin:, side:)
      iiif_base_path(coin: coin, side: side) + "/full/!400,400/0/default.jpg"
    end

    def thumbnail_uri(coin:, side:)
      iiif_base_path(coin: coin, side: side) + "/full/,120/0/default.jpg"
    end

    def iiif_base_path(coin:, side:)
      if side == "obverse"
        manifest_helper.manifest_image_path(coin.obverse_file_set)
      elsif side == "reverse"
        manifest_helper.manifest_image_path(coin.reverse_file_set)
      end
    end

    def manifest_helper
      @manifest_helper ||= ManifestBuilder::ManifestHelper.new
    end

    def title(coin)
      if coin.pub_created_display.present?
        coin.pub_created_display + ". #{coin.coin_number}"
      else
        coin.title.first
      end
    end

    def numismatics_collection_link
      "https://catalog.princeton.edu/numismatics"
    end

    def ark_link(coin)
      "http://arks.princeton.edu/#{coin.identifier.first}"
    end

    def query_service
      @query_service ||= ChangeSetPersister.default.query_service
    end

    def prefixes
      {
        nmo: NMO.to_s,
        void: VOID.to_s,
        dcterms: DCTERMS.to_s,
        foaf: FOAF.to_s,
        rdf: RDF.to_s,
        edm: EDM.to_s,
        svcs: SVCS.to_s,
        doap: DOAP.to_s
      }
    end

    def write_xml
      RDF::RDFXML::Writer.open(output_path, prefixes: prefixes, max_depth: MAX_DEPTH) do |writer|
        writer << graph
      end
    end
end
