# frozen_string_literal: true
class GeoMetadataExtractor
  class Iso19139
    attr_reader :doc
    def initialize(doc)
      @doc = doc
    end

    def extract
      {
        title: title,
        coverage: coverage,
        description: description,
        creator: creator,
        source: source
      }.compact
    end

    NS = {
      'xmlns:gmd' => 'http://www.isotc211.org/2005/gmd',
      'xmlns:gco' => 'http://www.isotc211.org/2005/gco'
    }.freeze

    def title
      doc.at_xpath('//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString', NS).text.strip
    end

    def coverage
      doc.at_xpath('//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox', NS).tap do |node|
        w = node.at_xpath('gmd:westBoundLongitude/gco:Decimal', NS).text.to_f
        e = node.at_xpath('gmd:eastBoundLongitude/gco:Decimal', NS).text.to_f
        n = node.at_xpath('gmd:northBoundLatitude/gco:Decimal', NS).text.to_f
        s = node.at_xpath('gmd:southBoundLatitude/gco:Decimal', NS).text.to_f
        return GeoResources::GeoCoverage.new(n, e, s, w).to_s
      end
      nil
    end

    def description
      doc.at_xpath('//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract/gco:CharacterString', NS).text.strip
    end

    def creator
      path = '//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue=\'originator\']'
      node = doc.xpath(path, NS)
      begin
        [node.at_xpath('ancestor-or-self::*/gmd:individualName', NS).text.strip]
      rescue
        [node.at_xpath('ancestor-or-self::*/gmd:organisationName', NS).text.strip]
      end
    end

    def source
      path = '//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue=\'custodian\']'
      node = doc.xpath(path, NS)
      begin
        [node.at_xpath('ancestor-or-self::*/gmd:individualName', NS).text.strip]
      rescue
        [node.at_xpath('ancestor-or-self::*/gmd:organisationName', NS).text.strip]
      end
    end
  end
end
