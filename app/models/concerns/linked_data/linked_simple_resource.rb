# frozen_string_literal: true
module LinkedData
  class LinkedSimpleResource < LinkedResource
    delegate(
      :alternative_title,
      :creator,
      :contributor,
      :publisher,
      :barcode,
      :local_identifier,
      :folder_number,
      :ephemera_project,
      :description,
      :height,
      :width,
      :sort_title,
      :page_count,
      :created_at,
      :updated_at,
      :folder_number,
      :ephemera_box,
      :date_created,
      to: :decorated_resource
    )

    private

      def properties
        {
          '@type': "pcdm:Object"
        }.merge(schema_properties)
      end

      def schema_properties
        resource.attributes.select do |k, v|
          Schema::Common.attributes.include?(k) && v.present? && !ignored_attributes.include?(k)
        end
      end

      def ignored_attributes
        [
          :pdf_type
        ]
      end
  end
end
