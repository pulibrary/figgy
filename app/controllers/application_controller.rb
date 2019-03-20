# frozen_string_literal: true
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  helper Openseadragon::OpenseadragonHelper
  layout "application"

  protect_from_forgery with: :exception

  def after_sign_in_path_for(_resource)
    request.env["omniauth.origin"] || root_path
  end

  def guest_uid_authentication_key(key)
    key &&= nil unless key.to_s =~ /^guest/
    return key if key
    "guest_" + guest_user_unique_suffix
  end

  rescue_from Blacklight::AccessControls::AccessDenied, CanCan::AccessDenied, with: :deny_resource_access
  def deny_resource_access(exception)
    respond_to do |format|
      format.json { head :forbidden }
      format.html do
        raise exception if :manifest == exception.action
        if current_user
          redirect_to root_url, alert: exception.message
        else
          redirect_to "/users/auth/cas", alert: exception.message
        end
      end
    end
  end

  rescue_from Valkyrie::Persistence::ObjectNotFoundError, with: :resource_not_found
  def resource_not_found(_exception)
    respond_to do |format|
      format.json { head :not_found }
      format.html do
        redirect_to root_url, alert: "The requested resource does not exist."
      end
    end
  end

  # Figgy has no use cases for having unique shared searches, and this prevents
  # the user list from growing out of control.
  def guest_user
    @guest_user ||= User.where(guest: true).first || super
  end

  # GET /viewer/config
  # Retrieve the viewer configuration for a given resource
  def viewer_config
    resource = find_resource

    config = if resource.decorate.downloadable? || (!current_user.nil? && (current_user.staff? || current_user.admin?))
               default_uv_config
             else
               downloads_disabled_uv_config
             end

    respond_to do |format|
      format.json { render json: config }
    end
  end

  private

    # Retrieve the ID of the resource from the parameters
    # @return [String]
    def resource_id
      params[:id]
    end

    # Retrieve the metadata adapter using Valkyrie
    # @return [Valkyrie::MetadataAdapter]
    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
    delegate :query_service, to: :metadata_adapter

    # Retrieve the resource using the ID of the resource
    # @return [Valkyrie::Resource]
    def find_resource
      query_service.find_by(id: Valkyrie::ID.new(resource_id))
    end

    # Construct a viewer configuration with the default options
    # @return [ViewerConfiguration]
    def default_uv_config
      ViewerConfiguration.new
    end

    # Construct a viewer configuration with downloads disabled
    # @return [ViewerConfiguration]
    def downloads_disabled_uv_config
      ViewerConfiguration.new(
        modules: {
          footerPanel: {
            options: {
              downloadEnabled: false
            }
          }
        }
      )
    end
end
