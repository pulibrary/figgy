# frozen_string_literal: true

module GeoResourceController
  extend ActiveSupport::Concern
  included do
    def extract_metadata
      change_set = ChangeSet.for(find_resource(params[:id]))
      authorize! :update, change_set.resource
      file_node = query_service.find_by(id: Valkyrie::ID.new(params[:file_set_id]))
      GeoMetadataExtractor.new(change_set: change_set, file_node: file_node, persister: change_set_persister).extract
    end
  end
end
