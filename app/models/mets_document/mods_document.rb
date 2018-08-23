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
      subject_names
    end

    def access_condition
      uris = value_from xpath: "mods:accessCondition[@type=\"useAndReproduction\"]/@xlink:href"
      return uris unless uris.empty?
      value_from xpath: "mods:accessCondition[@type=\"useAndReproduction\"]"
    end

    def restriction_on_access
      uris = value_from xpath: "mods:accessCondition[@type=\"restrictionOnAccess\"]/@xlink:href"
      return uris unless uris.empty?
      value_from xpath: "mods:accessCondition[@type=\"restrictionOnAccess\"]"
    end

    def abstract
      value_from xpath: "mods:abstract"
    end

    def table_of_contents
      value_from xpath: "mods:tableOfContents"
    end

    private

      def find_elements(xpath)
        @element.xpath(xpath, mods: MODS_XML_NAMESPACE, xlink: XLINK_XML_NAMESPACE)
      end

      def content(elements)
        elements.map(&:content)
      end

      def value_from(xpath:)
        elements = find_elements(xpath)
        content(elements)
      end

      def subject_names
        value_from xpath: "mods:subject/mods:name/mods:namePart"
      end
  end
end
