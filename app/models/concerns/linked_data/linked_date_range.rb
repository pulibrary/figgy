
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
        }
      end
  end
end
