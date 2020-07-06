# frozen_string_literal: true

module Cdl
  class CdlController < ApplicationController
    def status
      resource = query_service.find_by(id: params[:id])
      render json: CDL::Status.new(resource: resource, user: current_user)
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
