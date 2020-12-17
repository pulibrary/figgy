# frozen_string_literal: true

# Class modeling the MODS metadata within a METS Document
# @see https://www.loc.gov/standards/mods/
class METSDocument
  class MODSDocument
    MODS_XML_NAMESPACE = "http://www.loc.gov/mods/v3"
    XLINK_XML_NAMESPACE = "http://www.w3.org/1999/xlink"

    def self.from(mets:, xpath:)
      elements = mets.xpath(xpath, mets: METS_XML_NAMESPACE, mods: MODS_XML_NAMESPACE)
      return if elements.empty?

      new(elements.first)
    end

    def initialize(element)
      @element = element
    end

    def title
      element = find_elements("mods:titleInfo")
      title_value = element.entries.map do |entry|
        title = extract_element_children(entry, xpath: "mods:title")
        subtitle = extract_element_children(entry, xpath: "mods:subtitle")
        if subtitle.present?
          TitleWithSubtitle.new(title: title, subtitle: subtitle)
        else
          title
        end
      end
      return "#{non_sort} #{title_value}".gsub(/["\[\]]/, "") unless non_sort.empty?
      title_value
    end

    def sort_title
      return normalize_whitespace(value_from(xpath: "mods:titleInfo/mods:title")).join(",") unless non_sort.empty?
    end

    def non_sort
      normalize_whitespace(value_from(xpath: "mods:titleInfo/mods:nonSort")).join(",")
    end

    def publisher
      values = value_from(xpath: "mods:originInfo/mods:publisher")
      values.join(" - ")
    end

    def date_published
      normalize_whitespace(value_from(xpath: "mods:originInfo/mods:dateOther")).join(",")
    end

    def date_issued
      normalize_whitespace(value_from(xpath: "mods:originInfo/mods:dateIssued")).join(",")
    end

    def date_copyright
      normalize_whitespace(value_from(xpath: "mods:originInfo/mods:copyrightDate")).join(",")
    end

    def extract_element_children(entry, xpath:)
      content = content(find_elements(xpath, element: entry)).join(", ")
      return content unless (entry.attributes["lang"] || entry.attributes["script"]) && content.present?
      RDF::Literal.new(content, language: :"#{entry.attributes["lang"]}-#{entry.attributes["script"]}")
    end

    def alternative_title
      value_from xpath: "mods:titleInfo[@type=\"alternative\"]/mods:title"
    end

    def uniform_title
      value_from xpath: "mods:titleInfo[@type=\"uniform\"]/mods:title"
    end

    def creator
      value_from xpath: "mods:name[mods:role/mods:roleTerm[@type=\"code\"] = 'cre']/mods:namePart"
    end

    def photographer
      value_from xpath: "mods:name[mods:role/mods:roleTerm[@type=\"code\"] = 'pht']/mods:namePart"
    end

    def actor
      find_elements("mods:name[mods:role/mods:roleTerm[@type=\"code\"] = 'act']").entries.group_by { |x| x.attributes["altRepGroup"]&.value || SecureRandom.uuid }.map do |_group, entries|
        elements = entries.map do |entry|
          extract_element_children(entry, xpath: "mods:namePart")
        end
        if entries.length > 1
          Grouping.new(elements: elements)
        else
          elements.first
        end
      end
    end

    def director
      find_elements("mods:name[mods:role/mods:roleTerm[@type=\"code\"] = 'drt']").entries.map do |entry|
        extract_element_children(entry, xpath: "mods:namePart")
      end
    end

    def date_created
      values = value_from xpath: "mods:originInfo/mods:dateCreated"
      joined = values.join(" - ")
      Array.wrap(joined)
    end

    def type_of_resource
      value_from xpath: "mods:typeOfResource"
    end

    def extent
      value_from xpath: "mods:physicalDescription/mods:extent"
    end

    def note
      normalize_whitespace(value_from(xpath: "mods:note"))
    end

    def subject
      non_name_subjects + subject_names
    end

    def non_name_subjects
      normalize_whitespace(value_from(xpath: "mods:subject[not(./mods:name) and not(./mods:cartographics)]")).map(&:strip)
    end

    def coverage_point
      cartographics = find_elements("mods:subject/mods:cartographics")
      cartographics.flat_map do |cartographic|
        cartographic.xpath("mods:coordinates", mods: MODS_XML_NAMESPACE).map(&:content).map do |coord|
          lat, lon = coord.split("/")
          CoveragePoint.new(lat: lat.to_f, lon: lon.to_f)
        end
      end
    end

    def access_condition
      uris = value_from xpath: "mods:accessCondition[@type=\"useAndReproduction\"]/@xlink:href"
      return uris unless uris.empty?
      value_from xpath: "mods:accessCondition[@type=\"useAndReproduction\"]"
    end

    # in general we won't import this because it serves the same purpose as visibility
    def restriction_on_access
      uris = value_from xpath: "mods:accessCondition[@type=\"restrictionOnAccess\"]/@xlink:href"
      return uris unless uris.empty?
      value_from xpath: "mods:accessCondition[@type=\"restrictionOnAccess\"]"
    end

    def abstract
      normalize_whitespace(value_from(xpath: "mods:abstract"))
    end

    def table_of_contents
      value_from xpath: "mods:tableOfContents"
    end

    def genre
      value_from xpath: "mods:genre"
    end

    def physical_location
      normalize_whitespace(value_from(xpath: "mods:location/mods:physicalLocation[@type=\"text\"]"))
    end

    def holding_simple_sublocation
      value_from(xpath: "mods:location/mods:holdingSimple/mods:copyInformation/mods:subLocation")
    end

    def shelf_locator
      find_elements("mods:location/mods:holdingSimple/mods:copyInformation").entries.map do |entry|
        entry.children.select { |x| x.is_a?(Nokogiri::XML::Element) }.map(&:content).join(", ")
      end
    end

    # @return [String] the collection code if it was found, otherwise ""
    def collection_code
      return "" if finding_aid_identifier.empty?
      @collection_code ||= begin
        ark = Ark.new(finding_aid_identifier.first.identifier).ark
        result = IdentifierService.get_ark_result ark: ark
        result.rpartition("/").last
      end
    end

    def geographic_origin
      normalize_whitespace(value_from(xpath: "mods:originInfo/mods:place")).map(&:strip)
    end

    def geographic_subject
      value_from(xpath: "mods:subject/mods:geographic").map(&:strip).uniq
    end

    def language
      value_from(xpath: "mods:language/mods:languageTerm")
    end

    def series
      series_entries = find_elements("mods:relatedItem[@type=\"series\"]/mods:titleInfo")
      series_entries.map do |series|
        title = series.elements[0..1].map(&:content).join(" ")
        extra_elements = (series.elements[2..-1] || []).map(&:content).join(". ")
        [title, extra_elements].select(&:present?).join(". ")
      end
    end

    def finding_aid_identifier
      @finding_aid_identifiers ||= begin
        identifiers = find_elements("mods:relatedItem[@type=\"host\"][./mods:location/mods:url[@note='Finding Aid']]")
        identifiers.map do |identifier|
          title = identifier.xpath("mods:titleInfo/mods:title", mods: MODS_XML_NAMESPACE).first.content
          identifier = identifier.xpath("mods:location/mods:url", mods: MODS_XML_NAMESPACE).first.content
          ArkWithTitle.new(title: title, identifier: identifier)
        end
      end
    end

    def replaces
      element = @element.xpath("/mets:mets/@OBJID").to_s
      return nil if element.include?("ark")
      "http://pudl.princeton.edu/objects/#{element}"
    end

    def local_identifier
      value_from(xpath: "mods:identifier[@type=\"localAccession\"]") + value_from(xpath: "mods:identifier[@type=\"local\"]")
    end

    def record_identifier
      value_from(xpath: "//mods:recordIdentifier").first
    end

    private

      def find_elements(xpath, element: @element)
        element.xpath(xpath, mods: MODS_XML_NAMESPACE, xlink: XLINK_XML_NAMESPACE)
      end

      def content(elements)
        elements.map(&:content)
      end

      # @return Array<String>
      def value_from(xpath:)
        elements = find_elements(xpath)
        content(elements)
      end

      def subject_names
        names = find_elements("mods:subject/mods:name")
        names.map do |name|
          name.xpath("mods:namePart", mods: MODS_XML_NAMESPACE).map(&:content).join(", ")
        end
      end

      def normalize_whitespace(entries)
        entries.map { |s| s.gsub(/\s+/, " ") }
      end
  end
end
