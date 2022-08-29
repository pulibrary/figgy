# frozen_string_literal: true
class Ability
  include Hydra::Ability

  # Define any customized permissions here.
  self.ability_logic += [:manifest_permissions]

  def custom_permissions
    alias_action :show, :iiif_search, to: :read
    alias_action :color_pdf, :pdf, :edit, :browse_everything_files, :structure, :file_manager, :order_manager, to: :update
    roles.each do |role|
      send "#{role}_permissions" if current_user.send "#{role}?"
    end
    cannot [:create, :update, :destroy], :all if Figgy.read_only_mode
    cannot [:create, :update, :destroy], :all if Figgy.index_read_only?
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can [:manage], :all
  end

  # Staff can do anything except delete someone else's stuff
  def staff_permissions
    can [:create, :read, :download, :update, :manifest, :discover], :all
    can [:destroy], Template
    can [:destroy], OcrRequest
    can [:destroy], FileSet do |obj|
      obj.depositor == [current_user.uid] || (obj.persisted? && Wayfinder.for(obj).try(:parent)&.depositor == [current_user.uid])
    end
    can [:destroy], curation_concerns do |obj|
      obj.depositor == [current_user.uid]
    end
    cannot [:create, :destroy], Role
  end

  def anonymous_permissions
    can :pdf, curation_concerns do |resource|
      ["color", "gray"].include?(Array(resource.pdf_type).first)
    end
    can :download, curation_concerns do |resource|
      token_readable?(resource) || (resource.respond_to?(:visibility) && resource.visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC))
    end
    can :download, DownloadsController::FileWithMetadata do |resource|
      download_file_with_metadata?(resource)
    end
    can :download, FileSet do |resource|
      downloadable?(resource) && (authorized_by_token?(resource) || can_read_parent?(resource))
    end
    can :color_pdf, curation_concerns do |resource|
      resource.pdf_type == ["color"]
    end
    can :read, FileSet do |resource|
      can?(:read, resource.decorate.parent.object) || authorized_by_token?(resource)
    end
    can [:read], Numismatics::Monogram
    can [:read], :graphql
    can :refresh_remote_metadata, :json_document do
      current_user.groups.include?("metadata_refresh")
    end
  end

  # Abilities that should be granted to institutional patron
  def campus_patron_permissions
    anonymous_permissions

    can :download, DownloadsController::FileWithMetadata do |resource|
      download_file_with_metadata?(resource)
    end
  end

  def curation_concerns
    [ScannedResource, EphemeraFolder, ScannedMap, VectorResource, RasterResource, Playlist, Numismatics::Coin,
     Numismatics::Issue, Numismatics::Accession, Numismatics::Firm, Numismatics::Monogram, Numismatics::Person, Numismatics::Place, Numismatics::Reference]
  end

  def current_user
    TokenizedUser.new(super, auth_token)
  end

  def token_param
    options[:auth_token]
  end

  def stored_token
    @stored_token ||= AuthToken.find_by(token: token_param)
  end

  # Construct the AuthToken object from the parameter value in the HTTP request
  # @return [AuthToken]
  def auth_token
    return NilToken if token_param.nil? || stored_token.nil?
    stored_token
  end

  def download_file_with_metadata?(resource)
    # Geo thumbnails/metadata are always downloadable no matter what.
    return true if geo_thumbnail?(resource) || geo_metadata?(resource)
    file_set = query_service.find_by(id: resource.file_set_id)
    if resource.file_metadata.derivative? || resource.file_metadata.derivative_partial?
      can?(:read, file_set)
    else
      can?(:download, file_set)
    end
  end

  # Geo metadata is always downloadable
  def geo_metadata?(resource)
    ControlledVocabulary::GeoMetadataFormat.new.include?(resource.mime_type)
  end

  # Geo thumbnails are always downloadable
  def geo_thumbnail?(resource)
    return true if /thumbnail/.match?(resource.original_name)
    false
  end

  # The search builder uses this to enumerate actual names of states
  # @see app/models/search_builder.rb
  def unreadable_states
    return [] if universal_reader?
    WorkflowRegistry.all_states - WorkflowRegistry.public_read_states
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  def roles
    ["anonymous", "campus_patron", "admin", "staff"]
  end

  def universal_reader?
    current_user.staff? || current_user.admin?
  end

  def read_permissions
    super
    can :read, Valkyrie::Resource do |obj|
      valkyrie_test_read(obj) || valkyrie_test_edit(obj)
    end
    can :discover, Valkyrie::Resource do |obj|
      valkyrie_test_discover(obj)
    end
  end

  def edit_permissions
    super
    can [:edit, :update, :destroy], Valkyrie::Resource do |obj|
      valkyrie_test_edit(obj)
    end
  end

  def manifest_permissions
    can :manifest, Valkyrie::Resource do |obj|
      valkyrie_test_manifest(obj) || valkyrie_test_edit(obj)
    end
  end

  def valkyrie_test_manifest(obj)
    return false if embargoed?(obj)
    return false unless token_readable?(obj) || group_readable?(obj) || user_readable?(obj) || universal_reader? || ip_readable?(obj) || cdl_readable?(obj) || restricted_collection_viewer?(obj)
    # any group with :all permissions never hits this method
    #   other groups can only read published manifests, even if they have permissions indexed
    obj.decorate.manifestable_state?
  end

  def cdl_readable?(obj)
    resource_charge_list = Wayfinder.for(parent_or_self?(obj)).try(:resource_charge_list)
    return false unless resource_charge_list
    resource_charge_list.charged_items.reject(&:expired?).map(&:netid).include?(current_user.uid)
  end

  def cdl_eligible?(obj)
    return false unless obj.persisted?
    return false unless obj.decorate.public_readable_state?
    charge_manager(obj).eligible?
  end

  def charge_manager(obj)
    if cached_charge_manager&.resource_id&.to_s == obj.id.to_s
      cached_charge_manager
    else
      CDL::ChargeManager.new(resource_id: obj.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
    end
  end

  # Sometimes a charge manager is passed through from viewer auth to reduce the
  # calls to bibdata.
  def cached_charge_manager
    @cached_charge_manager ||= options.fetch(:charge_manager, nil)
  end

  def eligible_item_service
    CDL::EligibleItemService
  end

  def change_set_persister
    ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end

  def valkyrie_test_discover(obj)
    return true if valkyrie_test_read(obj)
    return true if restricted_collections?(obj)
    return false if obj.read_groups.include?(::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_READING_ROOM) && !reading_room_ip?
    return true if obj.decorate.public_readable_state? && !private?(obj)
    cdl_eligible?(obj) # check this last to minimize hits to alma API
  end

  def valkyrie_test_read(obj)
    return false if embargoed?(obj)
    return false unless token_readable?(obj) || group_readable?(obj) || user_readable?(obj) || universal_reader? || ip_readable?(obj) || cdl_readable?(obj) || restricted_collection_viewer?(obj)
    # any group with :all permissions never hits this method
    #   other groups can only read published manifests, even if they have permissions indexed
    obj.decorate.public_readable_state?
  end

  def restricted_collection_viewer?(obj)
    return false unless current_user && obj.decorate.public_readable_state?
    return false if private?(obj)
    collections = Wayfinder.for(obj).try(:self_or_parent_collections) || []
    collections.flat_map(&:restricted_viewers).include?(current_user.uid)
  end

  def restricted_collections?(obj)
    return false if private?(obj)
    collections = Wayfinder.for(obj).try(:collections) || []
    collections.flat_map(&:restricted_viewers).present?
  end

  def group_readable?(obj)
    groups = (user_groups & obj.read_groups)
    return reading_room_ip? if groups == [::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_READING_ROOM]
    groups.any?
  end

  def ip_readable?(obj)
    obj.read_groups == [::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_ON_CAMPUS] && campus_ip?
  end

  def reading_room_ip?
    reading_room_ips.include? current_user_ip
  end

  def reading_room_ips
    Figgy.config["access_control"]["reading_room_ips"]
  end

  def campus_ip?
    return false unless current_user_ip
    ip_addr = IPAddr.new(current_user_ip)
    Figgy.campus_ip_ranges.find { |range| range.include? ip_addr }.present?
  end

  def current_user_ip
    @current_user_ip ||= options.fetch(:ip_address, nil)
  end

  def user_readable?(obj)
    obj.read_users.include?(current_user.user_key)
  end

  def valkyrie_test_edit(obj)
    group_editable?(obj) || user_editable?(obj)
  end

  def group_editable?(obj)
    (user_groups & obj.edit_groups).any?
  end

  def user_editable?(obj)
    obj.edit_users.include?(current_user.user_key)
  end

  def downloadable?(obj)
    obj.decorate.downloadable? || authorized_by_token?(obj) || (!current_user.nil? && (current_user.staff? || current_user.admin?)) || authorized_downloadable_file_set?(obj)
  end

  def authorized_downloadable_file_set?(obj)
    return false unless obj.is_a?(FileSet)
    # Zip files can be downloaded if the user is authorized by restricted
    # collection viewership.
    obj.try(:mime_type).try(:first) == "application/zip" && restricted_collection_viewer?(parent_or_self?(obj))
  end

  def parent_or_self?(obj)
    Wayfinder.for(obj).try(:parent) || obj
  end

  # Null object pattern for auth. tokens
  class NilToken
    # No groups exist for these
    def self.group
      []
    end

    # These behave like nil Objects
    def self.nil?
      true
    end
  end

  class TokenizedUser < ::Draper::Decorator
    attr_reader :auth_token
    delegate_all

    def initialize(user, auth_token)
      @auth_token = auth_token
      super(user)
    end

    def groups
      @groups ||= super + auth_token.group
    end

    def campus_patron?
      persisted? && provider == "cas" || groups.include?("campus_patron")
    end

    def admin?
      groups.include?("admin")
    end
  end

  private

    # Retrieve a Resource using an identifier
    # @param id [String] the ID for the Resource
    # @return [Resource]
    def find_by(id:)
      query_service.find_by(id: id)
    end

    def find_proxy_file_sets(resource)
      query_service.find_inverse_references_by(resource: resource, property: :proxied_file_id)
    end

    def proxy_parent_readable?(resource)
      proxies = find_proxy_file_sets(resource)
      return if proxies.empty?

      proxy_parents = proxies.map { |proxy| proxy.decorate.parents.first }
      values = proxy_parents.map { |parent| token_readable?(parent) }
      values.reduce(:|)
    end

    # Overrides the default permissions for SolrDocument
    # @param id [String] the ID for the Solr Document
    # @return [Boolean]
    def test_read(id)
      return super if auth_token.nil?
      obj = find_by(id: id)
      token_readable?(obj) || super
    end

    def tokenized_access?(obj)
      obj.class.respond_to?(:tokenized_access?) && obj.class.tokenized_access?
    end

    # Determines whether or not a Resource is in its final workflow state
    # @param obj [Resource]
    # @return [Boolean]
    def final_state?(obj)
      obj.decorate.public_readable_state?
    end

    # Determines whether or not an auth token grants access to a given resource
    # @param obj [Resource]
    # @return [Boolean]
    def token_readable?(obj)
      return false unless !auth_token.nil? && tokenized_access?(obj)
      final_state?(obj) && obj.auth_token == auth_token.token
    end

    # Determines whether a resource has private visbility
    # @param obj [Resource]
    # @return [Boolean]
    def private?(obj)
      embargoed?(obj) || obj.decorate.try(:private_visibility?)
    end

    # Determines whether a resource's parent is readable because of an auth token
    # @param obj [Resource]
    # @return [Boolean]
    def authorized_by_token?(resource)
      proxy_parent_readable?(resource) || token_readable?(resource.decorate.parent) if auth_token
    end

    # Determines whether a resource's parent is readable
    # @param obj [Resource]
    # @return [Boolean]
    def can_read_parent?(resource)
      can?(:read, resource.decorate.parent&.object)
    end

    def embargoed?(obj)
      if obj.respond_to?(:embargo_date) && obj.embargo_date.present?
        Date.strptime(obj.embargo_date, "%m/%d/%Y") > Time.zone.today
      else
        false
      end
    end
end
