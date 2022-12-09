# frozen_string_literal: true
class Resource < Valkyrie::Resource
  enable_optimistic_locking
  def self.human_readable_type
    @human_readable_type ||=
      begin
        default = @_human_readable_type || name.demodulize.titleize
        I18n.translate("models.#{new.model_name.i18n_key}", default: default)
      end
  end

  def self.can_have_manifests?
    false
  end

  def self.tokenized_access?
    false
  end

  def human_readable_type
    self.class.human_readable_type
  end

  def self.model_name
    @model_name ||= ::ActiveModel::Name.new(self)
  end

  # Determines whether or not the "Save and Duplicate Metadata" is supported for this Resource
  # @return [Boolean]
  def self.supports_save_and_duplicate?
    false
  end

  def decorate
    @decorated_resource ||= super
  end

  def model_name
    @model_name ||= super
  end

  # Determines if this is an image resource
  # Used to determine the right characterization service
  # @return [TrueClass, FalseClass]
  def image_resource?
    false
  end

  # Determines if this is a geospatial resource
  # @return [TrueClass, FalseClass]
  def geo_resource?
    false
  end

  # Determines if this is a recording
  # @return [TrueClass, FalseClass]
  def recording?
    false
  end

  # Virtual property used for stashing pre-loaded objects. Populated by a query.
  attr_writer :loaded
  def loaded
    @loaded ||= {}
  end

  def linked_resource
    LinkedData::LinkedResource.new(resource: self)
  end
end
