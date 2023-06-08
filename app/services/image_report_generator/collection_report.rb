# frozen_string_literal: true
class ImageReportGenerator::CollectionReport
  attr_reader :collection_id, :date_range, :filter_microfilm
  # Microfilm digitization is usually excluded from these reports.
  def initialize(collection_id:, date_range:, filter_microfilm: true)
    @collection_id = collection_id
    @date_range = date_range
    @filter_microfilm = filter_microfilm
  end

  def to_row
    [
      collection.title.first, # Title
      grouped_members["open"]&.length, # Open Title Count
      grouped_members["restricted"]&.length, # Private Title Count
      grouped_members["reading_room"]&.length, # Reading Room Title Count
      grouped_members["authenticated"]&.length, # Princeton Only Title Count
      total_image_count(grouped_members["open"]), # Open Image Count
      total_image_count(grouped_members["restricted"]), # Private Image Count
      total_image_count(grouped_members["reading_room"]), # Reading Room Image Count
      total_image_count(grouped_members["authenticated"]) # Princeton Only Image Count
    ]
  end

  private

    def collection
      @collection ||= ChangeSetPersister.default.query_service.find_by(id: collection_id)
    end

    def members
      @members ||=
        begin
          members = query_service.custom_queries.find_by_property(
            property: :member_of_collection_ids,
            value: collection.id,
            created_at: date_range
          ).select do |member|
            # Filter out volumes.
            Wayfinder.for(member).parent.blank?
          end
          members.select do |member|
            # Filter out microfilm
            !filter_microfilm || !Array.wrap(member.call_number).any? { |x| x.to_s.include?("MICROFILM") }
          end
        end
    end

    def total_image_count(members)
      (members || []).map do |member|
        image_count(member)
      end.sum
    end

    def image_count(resource)
      query_service.custom_queries.find_deep_children_with_property(
        resource: resource,
        model: FileSet,
        property: :file_metadata,
        value: nil,
        count: true
      )
    end

    def query_service
      ChangeSetPersister.default.query_service
    end

    def grouped_members
      @grouped_members ||= members.group_by { |x| x.visibility.first }
    end
end
