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

    def date_range
      Array.wrap(decorated_resource.date_range).map { |r| LinkedDateRange.new(resource: r).without_context }.reject { |v| v.nil? || v.try(:empty?) }
    end

    def latitude
      Array.wrap(resource.coverage_point).map(&:lat).map(&:to_s)
    end

    def longitude
      Array.wrap(resource.coverage_point).map(&:lon).map(&:to_s)
    end

    private

      def properties
        {
          '@type': "pcdm:Object",
          date_range: try(:date_range),
          latitude: try(:latitude),
          longitude: try(:longitude)
        }.merge(schema_properties).merge(overwritten_properties)
      end

      def overwritten_properties
        {
          part_of: part_of,
          actor: actor
        }
      end

      def actor
        Array.wrap(resource.actor).map do |actor|
          if actor.is_a? Grouping
            {"grouping" => actor.elements}
          else
            actor
          end
        end
      end

      def part_of
        Array.wrap(resource.part_of).map do |part_of|
          {
            "@id" => part_of.identifier,
            "title" => part_of.title
          }
        end
      end

      def schema_properties
        resource.attributes.select do |k, v|
          Schema::Common.attributes.include?(k) && v.present? && !ignored_attributes.include?(k)
        end
      end

      def ignored_attributes
        [
          :pdf_type,
          :thumbnail_id,
          :coverage_point,
          :start_canvas
        ]
      end
  end
end
