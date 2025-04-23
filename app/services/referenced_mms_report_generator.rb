# frozen_string_literal: true

class ReferencedMmsReportGenerator
  def generate
    CSV.open(@csv_file, "wb") do |csv|
      csv << headers

      resources.each do |resource|
        entry = build_multi_volume_resource_entry(resource)
        next if entry.nil?

        csv << entry.values
      end

      @cache.each do |resource, parent|
        entry = build_resource_entry(resource)

        sub_collections = [parent.decorate.first_title]
        entry[:sub_collections] = sub_collections.join(";")
        sub_collection_ids = [parent.id]
        entry[:sub_collection_ids] = sub_collection_ids.join(";")

        csv << entry.values
      end
    end
  end

  def initialize(collection_id:, csv_file:)
    @collection_id = collection_id
    @csv_file = csv_file

    @cache = {}
  end

  private

    def new_entry
      {
        resource_id: nil,
        resource_type: nil,
        title: nil,
        ark: nil,
        mms_id: nil,
        collection_ids: nil,
        collections: nil,
        sub_collection_ids: nil,
        sub_collections: nil
      }
    end

    def headers
      new_entry.keys
    end

    def build_resource_entry(resource)
      collections = resource.decorate.member_of_collections
      collection_ids = collections.map(&:id)
      collection_titles = collections.map { |obj| obj.decorate.first_title }

      @members = resource.decorate.members

      @resource_type = resource.class.name
      sub_collections = []
      sub_collection_ids = []

      yield if block_given?

      identifiers = resource.identifier.presence || []
      source_metadata_identifiers = resource.source_metadata_identifier.presence || []

      new_entry.merge(
        {
          resource_id: resource.id,
          resource_type: @resource_type,
          title: resource.decorate.first_title,
          ark: identifiers.join(";"),
          mms_id: source_metadata_identifiers.join(";"),
          collection_ids: collection_ids.join(";"),
          collections: collection_titles.join(";"),
          sub_collection_ids: sub_collection_ids.join(";"),
          sub_collections: sub_collections.join(";")
        }
      )
    end

    def build_multi_volume_resource_entry(resource)
      build_resource_entry(resource) do
        if !@members.empty? && resource.is_a?(ScannedResource)

          volumes = resource.decorate.volumes
          return if volumes.empty?

          @resource_type = "Multi Volume Work"

          @members.each do |member|
            @cache[member] = resource
          end
        end
      end
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def collection
      @collection ||= query_service.find_by(id: @collection_id)
    end

    def collection_members
      @collection_members ||= collection.decorate.members
    end

    def resources
      @resources ||= collection_members.select { |resource| resource.source_metadata_identifier.present? }
    end
end
