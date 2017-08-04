# frozen_string_literal: true
module Valhalla
  module ResourceController
    extend ActiveSupport::Concern
    included do
      class_attribute :change_set_class, :resource_class, :change_set_persister
      delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
      delegate :persister, :query_service, to: :metadata_adapter
      include Blacklight::SearchContext
    end

    def new
      @change_set = change_set_class.new(resource_class.new).prepopulate!
      authorize! :create, resource_class
    end

    def create
      @change_set = change_set_class.new(resource_class.new)
      authorize! :create, @change_set.resource
      if @change_set.validate(resource_params)
        @change_set.sync
        obj = nil
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          obj = buffered_changeset_persister.save(change_set: @change_set)
        end
        redirect_to contextual_path(obj, @change_set).show
      else
        render :new
      end
    end

    def destroy
      @change_set = change_set_class.new(find_resource(params[:id]))
      authorize! :destroy, @change_set.resource
      change_set_persister.buffer_into_index do |persist|
        persist.delete(change_set: @change_set)
      end
      flash[:alert] = "Deleted #{@change_set.resource}"
      redirect_to root_path
    end

    def edit
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :update, @change_set.resource
    end

    def update
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :update, @change_set.resource
      if @change_set.validate(resource_params)
        @change_set.sync
        obj = nil
        change_set_persister.buffer_into_index do |persist|
          obj = persist.save(change_set: @change_set)
        end
        redirect_to contextual_path(obj, @change_set).show
      else
        render :edit
      end
    end

    def file_manager
      @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
      authorize! :file_manager, @change_set.resource
      @children = query_service.find_members(resource: @change_set).map do |x|
        change_set_class.new(x).prepopulate!
      end.to_a
    end

    def contextual_path(obj, change_set)
      Valhalla::ContextualPath.new(child: obj.id, parent_id: change_set.append_id)
    end

    def _prefixes
      @_prefixes ||= super + ['valhalla/base']
    end

    def resource_params
      params[resource_class.to_s.underscore.to_sym].to_unsafe_h
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end
  end
end
