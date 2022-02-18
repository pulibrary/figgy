# frozen_string_literal: true

module LinkedData
  class LinkedCollection < LinkedResource
    def title
      Array.wrap(decorated_resource.title).first
    end

    private

      def linked_properties
        {
          '@id': url,
          '@type': "pcdm:Collection",
          title: title
        }
      end
  end
end
