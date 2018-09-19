# frozen_string_literal: true
class Resource < Valkyrie::Resource
  def self.human_readable_type
    default = @_human_readable_type || name.demodulize.titleize
    I18n.translate("models.#{new.model_name.i18n_key}", default: default)
  end

  def self.can_have_manifests?
    false
  end

  def human_readable_type
    self.class.human_readable_type
  end

  def self.model_name
    ::ActiveModel::Name.new(self)
  end

  # Determines if this is an image resource
  # @return [TrueClass, FalseClass]
  def image_resource?
    false
  end

  # Determines if this is a geospatial resource
  # @return [TrueClass, FalseClass]
  def geo_resource?
    false
  end

  # Determines if this is a media resource
  # @return [TrueClass, FalseClass]
  def media_resource?
    false
  end

  # Virtual property used for stashing pre-loaded objects. Populated by a query.
  attr_accessor :loaded
  def loaded
    @loaded ||= {}
  end
end
