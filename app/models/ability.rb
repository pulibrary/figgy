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
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can [:manage], :all
  end

  # Staff can do anything except delete someone else's stuff
  def staff_permissions
    can [:create, :read, :download, :update, :manifest, :discover], :all
    can [:destroy], Template
    can [:destroy], FileSet do |obj|
      obj.depositor == [current_user.uid]
    end
    can [:destroy], curation_concerns do |obj|
      obj.depositor == [current_user.uid]
    end
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
      authorized_by_token?(resource) || geo_file_set?(resource) || can_read_parent?(resource)
    end
    can :color_pdf, curation_concerns do |resource|
      resource.pdf_type == ["color"]
    end
    can :read, FileSet do |resource|
      can?(:read, resource.decorate.parent.object)
    end
    can [:read], Numismatics::Monogram
    can [:read], :graphql
  end

  # Abilities that should be granted to institutional patron
  def campus_patron_permissions
    anonymous_permissions

    can :download, DownloadsController::FileWithMetadata do |resource|
      download_file_with_metadata?(resource) || geo_campus_file?(resource)
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
    @auth_token ||= AuthToken.find_by(token: token_param)
  end

  # Construct the AuthToken object from the parameter value in the HTTP request
  # @return [AuthToken]
  def auth_token
    return NilToken if token_param.nil? || stored_token.nil?
    stored_token
  end

  def download_file_with_metadata?(resource)
    token_readable_for_file_metadata?(resource) || pdf_file?(resource) || geo_thumbnail?(resource) || geo_metadata?(resource) || public_file?(resource)
  end

  # Geo metadata is always downloadable
  def geo_metadata?(resource)
    ControlledVocabulary::GeoMetadataFormat.new.include?(resource.mime_type)
  end

  # Find visibility of parent resource and return true if it's public
  def public_file?(resource)
    file_set = query_service.find_by(id: resource.file_set_id)
    visibility = file_set.decorate.parent.model.visibility
    visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end

  # Find visibility of parent geo resource and return true if it's authenticated
  def geo_campus_file?(resource)
    file_set = query_service.find_by(id: resource.file_set_id)
    parent = file_set.decorate.parent
    return unless parent.try(:geo_resource?)
    visibility = parent.model.visibility
    visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
  end

  def geo_file_set?(resource)
    return false unless resource.is_a?(FileSet)
    parent = resource.decorate.parent
    parent.try(:geo_resource?)
  end

  # Geo thumbnails are always downloadable
  def geo_thumbnail?(resource)
    return true if /thumbnail/ =~ resource.original_name
    false
  end

  def pdf_file?(resource)
    resource.mime_type == "application/pdf"
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
    return false unless token_readable?(obj) || group_readable?(obj) || user_readable?(obj) || universal_reader? || ip_readable?(obj)
    # any group with :all permissions never hits this method
    #   other groups can only read published manifests, even if they have permissions indexed
    obj.decorate.manifestable_state?
  end

  def valkyrie_test_discover(obj)
    return true if valkyrie_test_read(obj)
    return false if obj.read_groups.include?(::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_READING_ROOM) && !reading_room_ip?
    obj.decorate.public_readable_state? && !private?(obj)
  end

  def valkyrie_test_read(obj)
    return false unless token_readable?(obj) || group_readable?(obj) || user_readable?(obj) || universal_reader? || ip_readable?(obj)
    # any group with :all permissions never hits this method
    #   other groups can only read published manifests, even if they have permissions indexed
    obj.decorate.public_readable_state?
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
      obj.read_groups.empty?
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

    # Determines whether or not an auth token grants access to the parent of a given resource
    # @param obj [Resource]
    # @return [Boolean]
    def token_readable_for_file_metadata?(obj)
      return false unless auth_token && obj.respond_to?(:file_set_id)
      # This is not always a FileSet, as PDFs are attached directly to ScannedResources
      attaching_resource = find_by(id: obj.file_set_id)

      return if attaching_resource.nil?
      return token_readable?(attaching_resource) unless attaching_resource.is_a?(FileSet)

      # Retrieve the Playlist
      authorized_by_token?(attaching_resource)
    end
end
