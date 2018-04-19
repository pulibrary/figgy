# frozen_string_literal: true
module GeoResourceController
  extend ActiveSupport::Concern
  included do
    def extract_metadata
      change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :update, change_set.resource
      file_node = query_service.find_by(id: Valkyrie::ID.new(params[:file_set_id]))
      GeoMetadataExtractor.new(change_set: change_set, file_node: file_node, persister: persister).extract
    end
  end
end
