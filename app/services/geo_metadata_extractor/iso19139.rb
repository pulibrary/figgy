# frozen_string_literal: true
class GeoMetadataExtractor
  class Iso19139
    attr_reader :doc
    def initialize(doc)
      @doc = doc
    end

    def extract
      metadata_required.merge(metadata_optional)
    end

    def metadata_required
      {
        coverage: coverage,
        creator: creator,
        description: description,
        title: title
      }.compact
    end

    def metadata_optional
      {
        issued: issued,
        publisher: publisher,
        spatial: spatial,
        subject: subject,
        temporal: temporal
      }.compact
    end

    NS = {
      "xmlns:gmd" => "http://www.isotc211.org/2005/gmd",
      "xmlns:gco" => "http://www.isotc211.org/2005/gco"
    }.freeze

    def title
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString"
      extract_text(doc, path)
    end

    def coverage
      doc.at_xpath("//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:extent/gmd:EX_Extent/gmd:geographicElement/gmd:EX_GeographicBoundingBox", NS).tap do |node|
        w = node.at_xpath("gmd:westBoundLongitude/gco:Decimal", NS).text.to_f
        e = node.at_xpath("gmd:eastBoundLongitude/gco:Decimal", NS).text.to_f
        n = node.at_xpath("gmd:northBoundLatitude/gco:Decimal", NS).text.to_f
        s = node.at_xpath("gmd:southBoundLatitude/gco:Decimal", NS).text.to_f
        return GeoCoverage.new(n, e, s, w).to_s
      end
      nil
    end

    def description
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:abstract/gco:CharacterString"
      extract_text(doc, path)
    end

    def creator
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='originator']"
      nodes = doc.xpath(path, NS)
      extract_names(nodes)
    end

    def publisher
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:citedResponsibleParty/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue='publisher']"
      nodes = doc.xpath(path, NS)
      extract_names(nodes)
    end

    def issued
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:Date"
      extract_text(doc, path)
    end

    def spatial
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='place']/../../gmd:keyword"
      nodes = doc.xpath(path, NS)
      placenames = nodes.map do |node|
        extract_text(node)
      end.uniq

      placenames.present? ? placenames : nil
    end

    def topic
      nodes = doc.xpath("//gmd:MD_TopicCategoryCode", NS)
      topics = nodes.map do |node|
        value = extract_text(node)

        TOPIC_CATEGORIES[value.to_sym].present? ? TOPIC_CATEGORIES[value.to_sym] : value
      end.uniq

      topics.present? ? topics : nil
    end

    def theme
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='theme']/../../gmd:keyword"
      nodes = doc.xpath(path, NS)
      themes = nodes.map do |node|
        extract_text(node)
      end.uniq

      themes.present? ? themes : nil
    end

    def subject
      values = topic.concat(theme).uniq
      values.present? ? values : nil
    end

    def temporal
      path = "//gmd:identificationInfo/gmd:MD_DataIdentification/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:type/gmd:MD_KeywordTypeCode[@codeListValue='temporal']/../../gmd:keyword"
      nodes = doc.xpath(path, NS)
      timeperiods = nodes.map do |node|
        extract_text(node)
      end.uniq

      timeperiods.present? ? timeperiods : nil
    end

    # ISO 19115 Topic Category
    TOPIC_CATEGORIES = {
      farming: "Farming",
      biota: "Biology and Ecology",
      climatologyMeteorologyAtmosphere: "Climatology, Meteorology and Atmosphere",
      boundaries: "Boundaries",
      elevation: "Elevation",
      environment: "Environment",
      geoscientificinformation: "Geoscientific Information",
      health: "Health",
      imageryBaseMapsEarthCover: "Imagery and Base Maps",
      intelligenceMilitary: "Military",
      inlandWaters: "Inland Waters",
      location: "Location",
      oceans: "Oceans",
      planningCadastre: "Planning and Cadastral",
      structure: "Structures",
      transportation: "Transportation",
      utilitiesCommunication: "Utilities and Communication",
      society: "Society"
    }.freeze

    private

      def extract_names(nodes)
        values = nodes.map do |node|
          name = extract_text(node, "ancestor-or-self::*/gmd:individualName")
          org = extract_text(node, "ancestor-or-self::*/gmd:organisationName")
          if name && org
            "#{name}, #{org}"
          else
            name || org
          end
        end.uniq

        values.present? ? values : nil
      end

      def extract_text(node, path = nil)
        node = node.at_xpath(path, NS) if path
        node&.text&.strip
      end
  end
end
