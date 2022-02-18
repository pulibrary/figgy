# frozen_string_literal: true

module LinkedData
  class LinkedDateRange < LinkedResource
    private

      def linked_properties
        return {} if resource.start.blank? || resource.end.blank?
        {
          "@type" => "edm:TimeSpan",
          "begin" => resource.start,
          "end" => resource.end
        }.tap do |props|
          props["skos:prefLabel"] = resource.decorate.range_string if resource.approximate
          props["crm:P79_beginning_is_qualified_by"] = "approximate" if resource.approximate
          props["crm:P80_end_is_qualified_by"] = "approximate" if resource.approximate
        end
      end
  end
end
