# frozen_string_literal: true
class Ability
  include Valhalla::Ability
  # Define any customized permissions here.
  def custom_permissions
    alias_action :show, :manifest, to: :read
    alias_action :color_pdf, :pdf, :edit, :browse_everything_files, :structure, :file_manager, to: :modify
    roles.each do |role|
      send "#{role}_permissions" if current_user.send "#{role}?"
    end
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can [:manage], :all
  end

  def anonymous_permissions
    # do not allow viewing incomplete resources
    curation_concern_read_permissions
  end

  # Abilities that should be granted to patron
  def campus_patron_permissions
    anonymous_permissions
  end

  def completer_permissions
    can [:read, :modify, :update], curation_concerns
    can [:read, :edit, :update], FileSet
    can [:read, :edit, :update], Collection

    # allow completing resources
    can [:complete], curation_concerns

    curation_concern_read_permissions
  end

  def curation_concern_read_permissions
    cannot [:read], curation_concerns do |resource|
      !readable_concern?(resource)
    end
    cannot [:manifest], EphemeraFolder do |resource|
      !manifestable_concern?(resource)
    end
    can :pdf, curation_concerns do |resource|
      ["color", "gray"].include?(Array(resource.pdf_type).first)
    end
    can :download, curation_concerns do |resource|
      resource.respond_to?(:visibility) && resource.visibility.include?(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    end
    can :download, Valhalla::DownloadsController::FileWithMetadata do |resource|
      download_file_with_metadata?(resource)
    end
    can :download, FileSet do |resource|
      geo_file_set?(resource)
    end
    can :color_pdf, curation_concerns do |resource|
      resource.pdf_type == ["color"]
    end
  end

  def curator_permissions
    can [:read], curation_concerns
    can [:read], FileSet
    can [:read], Collection

    # do not allow viewing pending resources
    curation_concern_read_permissions
  end

  def editor_permissions
    can [:read, :modify, :update], curation_concerns
    can [:read, :edit, :update], FileSet
    can [:read, :edit, :update], Collection

    # do not allow completing resources
    cannot [:complete], curation_concerns

    curation_concern_read_permissions
  end

  # Abilities that should be granted to ephemera editors
  def ephemera_editor_permissions
    ephemera_permissions
    can [:create, :read, :edit, :update, :publish], Collection
    can [:create, :read, :edit, :update, :publish, :download], FileSet
    can [:destroy], FileSet do |obj|
      obj.depositor == [current_user.uid]
    end
  end

  def ephemera_permissions
    can [:manage], EphemeraBox
    can [:manage], EphemeraFolder
    can [:manage], Template
  end

  def fulfiller_permissions
    can [:read], curation_concerns
    can [:read, :download], FileSet
    can [:read], Collection
    curation_concern_read_permissions
  end

  # Abilities that should be granted to technicians
  def image_editor_permissions
    ephemera_permissions
    can [:read, :create, :modify, :update, :publish], curation_concerns
    can [:create, :read, :edit, :update, :publish, :download, :derive], FileSet
    can [:create, :read, :edit, :update, :publish], Collection

    # do not allow completing resources
    cannot [:complete], curation_concerns

    # only allow deleting for own objects, without ARKs
    can [:destroy], FileSet do |obj|
      obj.depositor == [current_user.uid]
    end
    can [:destroy], curation_concerns do |obj|
      obj.depositor == [current_user.uid]
    end
    cannot [:destroy], curation_concerns do |obj|
      !obj.try(:identifier).blank?
    end
  end

  def auth_token
    @auth_token ||= AuthToken.find_by(token: options[:auth_token]) || NilToken
  end

  def curation_concerns
    [ScannedResource, EphemeraFolder, ScannedMap, VectorResource, RasterResource, SimpleResource]
  end

  def current_user
    TokenizedUser.new(super, auth_token)
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
    resource.mime_type == 'application/pdf'
  end

  def manifestable_concern?(resource)
    resource.decorate.manifestable_state?
  end

  def readable_concern?(resource)
    return false if unreadable_states.include? Array.wrap(resource.state).first
    return true if universal_reader?
    resource.decorate.public_readable_state?
  end

  # also used by search builder
  def unreadable_states
    return ["pending"] if current_user.curator?
    return [] if universal_reader?
    WorkflowRegistry.all_states - WorkflowRegistry.public_read_states
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  def roles
    ['anonymous', 'campus_patron', 'completer', 'curator', 'fulfiller', 'editor', 'ephemera_editor', 'image_editor', 'admin']
  end

  def universal_reader?
    current_user.curator? || current_user.image_editor? || current_user.completer? || current_user.fulfiller? || current_user.editor? || current_user.admin?
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

    def ephemera_editor?
      groups.include?('ephemera_editor')
    end

    def image_editor?
      groups.include?('image_editor')
    end

    def editor?
      groups.include?('editor')
    end

    def fulfiller?
      groups.include?('fulfiller')
    end

    def curator?
      groups.include?('curator')
    end

    def campus_patron?
      persisted? && provider == "cas" || groups.include?('campus_patron')
    end

    def admin?
      groups.include?('admin')
    end
  end
end
