# frozen_string_literal: true
class GeoMetadataExtractor
  class Fgdc
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
        creator: creators,
        description: [doc.at_xpath("//idinfo/descript/abstract").text],
        title: [doc.at_xpath("//idinfo/citation/citeinfo/title").text]
      }.compact
    end

    def metadata_optional
      {
        issued: issued,
        publisher: publishers,
        spatial: placenames,
        subject: keywords,
        temporal: timeperiods
      }.compact
    end

    def coverage
      doc.at_xpath("//idinfo/spdom/bounding").tap do |node|
        return GeoCoverage.new(
          coverage_coordinate(node, "north"),
          coverage_coordinate(node, "east"),
          coverage_coordinate(node, "south"),
          coverage_coordinate(node, "west")
        ).to_s
      end
      nil
    end

    def coverage_coordinate(node, direction)
      node.at_xpath("#{direction}bc").text.to_f
    end

    def issued
      doc.at_xpath("//idinfo/citation/citeinfo/pubdate").tap do |node|
        return node.text[0..3].to_i unless node.nil? # extract year only
      end
      nil
    end

    def timeperiods
      TimePeriod.new(
        extract_multivalued("//idinfo/keywords/temporal/tempkey"), doc
      ).value
    end

    def publishers
      extract_multivalued("//idinfo/citation/citeinfo/pubinfo/publish")
    end

    def creators
      extract_multivalued("//idinfo/citation/citeinfo/origin")
    end

    def placenames
      extract_multivalued("//idinfo/keywords/place/placekey")
    end

    def keywords
      keywords = extract_multivalued("//idinfo/keywords/theme/themekey")
      keywords.map! { |k| TOPIC_CATEGORIES[k.to_sym].presence || k }
      keywords.uniq!
      keywords.presence
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

      def extract_multivalued(xpath)
        values = []
        doc.xpath(xpath).each do |node|
          values << node.text.strip
        end
        values.uniq!
        values.presence
      end
  end
end
