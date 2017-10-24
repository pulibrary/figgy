
# frozen_string_literal: true
module LinkedData
  class LinkedDateRange < LinkedResource
    def local_fields
      {
        "@type" => "edm:TimeSpan",
        "begin" => resource.start,
        "end" => resource.end
      }
    end

    def basic_jsonld
      {}
    end

    def without_context
      as_jsonld.except("@context")
    end
  end
end
