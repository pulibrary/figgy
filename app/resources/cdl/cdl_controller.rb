# frozen_string_literal: true

module Cdl
  class CdlController < ApplicationController
    def status
      @charge_manager = charge_manager(params[:id])
      render json: CDL::Status.new(charge_manager: @charge_manager, user: current_user)
    end

    def charge
      return forbidden unless current_user
      @charge_manager = charge_manager(params[:id])
      @charge_manager.create_charge(netid: current_user.uid)
      redirect_to auth_viewer_path(params[:id])
    rescue CDL::UnavailableForCharge
      flash[:alert] = "This item is not currently available for check out."
      redirect_to auth_viewer_path(params[:id])
    end

    def hold
      return forbidden unless current_user
      @charge_manager = charge_manager(params[:id])
      @charge_manager.create_hold(netid: current_user.uid)
      redirect_to auth_viewer_path(params[:id])
    rescue CDL::HoldExists
      flash[:alert] = "You already have a reservation for this item."
      redirect_to auth_viewer_path(params[:id])
    end

    def forbidden
      head :forbidden
    end

    def charge_manager(resource_id)
      CDL::ChargeManager.new(
        resource_id: resource_id,
        eligible_item_service: CDL::EligibleItemService,
        change_set_persister: change_set_persister
      )
    end

    def change_set_persister
      ChangeSetPersister.new(
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
  end
end
