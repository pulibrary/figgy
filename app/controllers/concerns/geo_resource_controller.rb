# frozen_string_literal: true
module GeoResourceController
  extend ActiveSupport::Concern
  included do
    def file_manager
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :file_manager, @change_set.resource
      populate_children
    end

    def extract_metadata
      change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :update, change_set.resource
      file_node = query_service.find_by(id: Valkyrie::ID.new(params[:file_set_id]))
      GeoMetadataExtractor.new(change_set: change_set, file_node: file_node, persister: persister).extract
    end

    private

      def populate_children
        @children = decorated_resource.geo_members.map do |x|
          change_set_class.new(x).prepopulate!
        end.to_a

        @metadata_children = decorated_resource.geo_metadata_members.map do |x|
          change_set_class.new(x).prepopulate!
        end.to_a
      end

      def decorated_resource
        @change_set.resource.decorate
      end
  end
end
