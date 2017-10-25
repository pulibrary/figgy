# frozen_string_literal: true
module LinkedData
  class LinkedCollection < LinkedResource
    private

      def linked_properties
        {
          '@id': url,
          '@type': 'pcdm:Collection',
          title: title
        }
      end
  end
end
