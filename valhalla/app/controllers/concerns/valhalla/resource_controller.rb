# frozen_string_literal: true
module Valhalla
  module ResourceController
    extend ActiveSupport::Concern
    included do
      class_attribute :change_set_class, :resource_class, :change_set_persister
      delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
      delegate :persister, :query_service, to: :metadata_adapter
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
        persister.buffer_into_index do |buffered_adapter|
          change_set_persister.with(metadata_adapter: buffered_adapter) do |buffered_changeset_persister|
            obj = buffered_changeset_persister.save(change_set: @change_set)
          end
        end
        redirect_to contextual_path(obj, @change_set).show
      else
        render :new
      end
    end

    def destroy
      @change_set = change_set_class.new(find_resource(params[:id]))
      authorize! :destroy, @change_set.resource
      persister.buffer_into_index do |buffered_adapter|
        change_set_persister.with(metadata_adapter: buffered_adapter) do |persist|
          persist.delete(change_set: @change_set)
        end
      end
      flash[:alert] = "Deleted #{@change_set.resource}"
      redirect_to root_path
    end

    def contextual_path(obj, change_set)
      Valhalla::ContextualPath.new(child: obj.id, parent_id: change_set.append_id)
    end

    def _prefixes
      @_prefixes ||= super + ['valhalla/base']
    end

    def resource_params
      params[resource_class.to_s.underscore.to_sym]
    end

    def find_resource(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end
  end
end
