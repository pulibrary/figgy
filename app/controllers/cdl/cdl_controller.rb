# frozen_string_literal: true

module CDL
  class CDLController < ApplicationController
    def status
      @charge_manager = charge_manager(params[:id])
      render json: CDL::Status.new(charge_manager: @charge_manager, user: current_user)
    end

    def charge
      return forbidden unless current_user
      retry_stale do
        @charge_manager = charge_manager(params[:id])
        @charge_manager.create_charge(netid: current_user.uid)
      end
      redirect_to auth_viewer_path(params[:id])
    rescue CDL::UnavailableForCharge
      flash[:alert] = "This item is not currently available for check out."
      redirect_to auth_viewer_path(params[:id])
    end

    def hold
      return forbidden unless current_user
      retry_stale do
        @charge_manager = charge_manager(params[:id])
        @charge_manager.create_hold(netid: current_user.uid)
      end
      redirect_to auth_viewer_path(params[:id])
    rescue CDL::HoldExists
      flash[:alert] = "You have already reserved this item."
      redirect_to auth_viewer_path(params[:id])
    end

    def return
      return forbidden unless current_user
      retry_stale do
        @charge_manager = charge_manager(params[:id])
        @charge_manager.return(netid: current_user.uid)
      end
      flash[:notice] = "Thank you for returning this item."
      redirect_to auth_viewer_path(params[:id])
    rescue CDL::NotCharged
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

    private

      def retry_stale(times: 5)
        count ||= 1
        yield
      rescue Valkyrie::Persistence::StaleObjectError
        count += 1
        retry if count < times
      end
  end
end
