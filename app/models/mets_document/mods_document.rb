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
      value_from xpath: "mods:titleInfo/mods:title"
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
      value_from xpath: "mods:note"
    end

    def subject
      non_name_subjects + subject_names
    end

    def non_name_subjects
      normalize_whitespace(value_from(xpath: "mods:subject[not(./mods:name)]")).map(&:strip)
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
      value_from(xpath: "mods:location/mods:holdingSimple/mods:copyInformation/mods:shelfLocator")
    end

    def geographic_origin
      normalize_whitespace(value_from(xpath: "mods:originInfo/mods:place")).map(&:strip)
    end

    def language
      value_from(xpath: "mods:language/mods:languageTerm")
    end

    def series
      series_entries = find_elements("mods:relatedItem[@type=\"series\"]/mods:titleInfo")
      series_entries.map do |series|
        title = series.elements[0..1].map(&:content).join(" ")
        title + ". " + series.elements[2..-1].map(&:content).join(". ")
      end
    end

    def finding_aid_identifier
      identifiers = find_elements("mods:relatedItem[@type=\"host\"][./mods:location/mods:url[@note='Finding Aid']]")
      identifiers.map do |identifier|
        title = identifier.xpath("mods:titleInfo/mods:title", mods: MODS_XML_NAMESPACE).first.content
        identifier = identifier.xpath("mods:location/mods:url", mods: MODS_XML_NAMESPACE).first.content
        ArkWithTitle.new(title: title, identifier: identifier)
      end
    end

    def replaces
      element = @element.xpath("/mets:mets/@OBJID").to_s
      return nil if element.include?("ark")
      "http://pudl.princeton.edu/objects/#{element}"
    end

    private

      def find_elements(xpath)
        @element.xpath(xpath, mods: MODS_XML_NAMESPACE, xlink: XLINK_XML_NAMESPACE)
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
