# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  helper Openseadragon::OpenseadragonHelper
  layout "application"

  protect_from_forgery with: :exception

  before_action :authorize_mini_profiler
  before_action :store_user_location!, if: :storable_location?

  def after_sign_out_path_for(_resource)
    Rails.configuration.x.after_sign_out_url
  end

  def current_ability
    Ability.new(current_user, ip_address: request.remote_ip)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || root_path
  end

  def guest_uid_authentication_key(key)
    key &&= nil unless /^guest/.match?(key.to_s)
    return key if key
    "guest_" + guest_user_unique_suffix
  end

  rescue_from Blacklight::AccessControls::AccessDenied, CanCan::AccessDenied, with: :deny_resource_access
  def deny_resource_access(exception)
    respond_to do |format|
      format.json do
        if exception.action == :manifest && @resource.present?
          manifest_denial
        else
          head :forbidden
        end
      end
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

  def manifest_denial
    if current_ability.can?(:discover, @resource)
      head :unauthorized
    else
      head :forbidden
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
    resource = find_resource(resource_id_param)
    respond_to do |format|
      format.json { render json: viewer_config_value(resource) }
    end
  end

  def viewer_config_value(resource)
    return default_uv_config if full_viewer_capability?(resource)
    downloads_disabled_uv_config.tap do |config|
      config.disable_share! if cdl_eligible?(resource)
    end
  end

  def cdl_eligible?(resource)
    CDL::ChargeManager.new(
      resource_id: resource.id,
      eligible_item_service: CDL::EligibleItemService,
      change_set_persister: ChangeSetPersister.new(
        metadata_adapter: Valkyrie.config.metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    ).eligible?
  end

  def full_viewer_capability?(resource)
    resource.decorate.downloadable? || (!current_user.nil? && (current_user.staff? || current_user.admin?))
  end

  # GET /viewer/exhibit/config
  # Retrieve the viewer configuration for a given resource in a digital exhibit
  def viewer_exhibit_config
    return head(:bad_request) unless manifest_url_param

    resource = find_resource_from_manifest(manifest_url_param)

    config = if resource.decorate.downloadable?
      default_exhibit_uv_config
    else
      downloads_disabled_exhibit_uv_config
    end

    respond_to do |format|
      format.json { render json: config }
      format.html { render json: config }
    end
  end

  private

    # Retrieve the ID of the resource from the parameters
    # @return [String]
    def resource_id_param
      params[:id]
    end

    # Retrieve the manifest URL from the request parameters
    # @return [String]
    def manifest_url_param
      params[:manifest]
    end

    # Retrieve the metadata adapter using Valkyrie
    # @return [Valkyrie::MetadataAdapter]
    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
    delegate :query_service, to: :metadata_adapter

    # Retrieve the resource using the ID of the resource
    # @param resource_id [String]
    # @return [Valkyrie::Resource]
    def find_resource(resource_id)
      query_service.find_by(id: Valkyrie::ID.new(resource_id))
    end

    # This needs to be opinionated about the structure of the URL
    # @param url [String] the URL to the manifest
    # @return [Valkyrie::Resource]
    def find_resource_from_manifest(url)
      components = url.split("/")
      return unless !components.empty? && components.last == "manifest"
      id = components[-2]
      find_resource(id)
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

    def default_exhibit_uv_config
      ExhibitViewerConfiguration.new
    end

    def downloads_disabled_exhibit_uv_config
      ExhibitViewerConfiguration.new(
        modules: {
          footerPanel: {
            options: {
              downloadEnabled: false
            }
          }
        }
      )
    end

    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
    end

    def store_user_location!
      # :user is the scope we are authenticating
      store_location_for(:user, request.fullpath)
    end

    # :nocov:
    def authorize_mini_profiler
      return unless Rails.env.staging? || Rails.env.development?
      return unless current_user&.admin?
      Rack::MiniProfiler.authorize_request
    end
  # :nocov:
end
