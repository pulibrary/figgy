# frozen_string_literal: true
class ScannedMapsController < ScannedResourcesController
  self.resource_class = ScannedMap

  def file_manager
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :file_manager, @change_set.resource
    populate_children
  end

  private

    def populate_children
      @children = decorated_resource.geo_image_members.map do |x|
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
