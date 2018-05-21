# frozen_string_literal: true
class Ability
  include Hydra::Ability
  # Define any customized permissions here.

  self.ability_logic +=[:manifest_permissions]

  def custom_permissions
    alias_action :show, to: :read
    alias_action :color_pdf, :pdf, :edit, :browse_everything_files, :structure, :file_manager, :order_manager, to: :modify
    roles.each do |role|
      send "#{role}_permissions" if current_user.send "#{role}?"
    end
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can [:manage], :all
  end

  # Staff can do anything except delete someone else's stuff
  def staff_permissions
    can [:create, :read, :modify, :update], :all
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
      resource.respond_to?(:visibility) && resource.visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    end
    can :download, DownloadsController::FileWithMetadata do |resource|
      download_file_with_metadata?(resource)
    end
    can :download, FileSet do |resource|
      geo_file_set?(resource)
    end
    can :color_pdf, curation_concerns do |resource|
      resource.pdf_type == ["color"]
    end
    can :read, FileSet do |resource|
      can?(:read, resource.decorate.parent.object)
    end
  end

  # Abilities that should be granted to institutional patron
  def campus_patron_permissions
    anonymous_permissions
  end

  def curation_concerns
    [ScannedResource, EphemeraFolder, ScannedMap, VectorResource, RasterResource, SimpleResource]
  end

  def current_user
    TokenizedUser.new(super, auth_token)
  end

  def auth_token
    @auth_token ||= AuthToken.find_by(token: options[:auth_token]) || NilToken
  end

  def download_file_with_metadata?(resource)
    pdf_file?(resource) || geo_thumbnail?(resource) || geo_metadata?(resource) || geo_public_file?(resource)
  end

  # Geo metadata is always downloadable
  def geo_metadata?(resource)
    ControlledVocabulary::GeoMetadataFormat.new.include?(resource.mime_type)
  end

  # Find visibility of parent geo resource and return true if it's public
  def geo_public_file?(resource)
    file_set = query_service.find_by(id: resource.file_set_id)
    visibility = file_set.decorate.parent.model.visibility
    visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
  end

  def geo_file_set?(resource)
    return false unless resource.is_a?(FileSet)
    parent = resource.decorate.parent
    parent.try(:geo_resource?)
  rescue StandardError
    false
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
    if group_readable?(obj) || user_readable?(obj) || universal_reader?
      # some groups can only read published manifests, even if they have permissions indexed
      if !current_user.admin? && !current_user.staff?
        obj.decorate.manifestable_state?
      else
        true
      end
    end
  end

  def valkyrie_test_read(obj)
    if group_readable?(obj) || user_readable?(obj) || universal_reader?
      # some groups can only read published documents, even if they have permissions indexed
      if !current_user.admin? && !current_user.staff?
        obj.decorate.public_readable_state?
      else
        true
      end
    end
  end

  def group_readable?(obj)
    (user_groups & obj.read_groups).any?
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

  class NilToken
    def self.group
      []
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
end
