# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class BaseResourceController < ApplicationController
  include Valhalla::ResourceController
  include TokenAuth
  before_action :load_collections, only: [:new, :edit]

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate)
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    @change_set ||= change_set_class.new(resource)
  end
end
