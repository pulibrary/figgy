# frozen_string_literal: true
class BaseWayfinder
  # Creates relationship methods `relationship` and `decorated_relationship`
  # which accesses a given property and queries for all IDs contained within.
  #
  # @param relationship [Symbol] Name of the relationship, will become the
  #   method name created.
  # @param property [Symbol] Name of the property which stores IDs for the
  #   relationship. If the property is member_ids, it will return records in
  #   order.
  # @param singular [Boolean] Creates singular methods as well if true (IE
  #   ephemera_project if relationship is ephemera_projects)
  # @param model [Class] Model to filter results by.
  def self.relationship_by_property(relationship, property:, singular: false, model: nil)
    return member_relationship(relationship, model: model) if property == :member_ids
    define_method relationship do
      return instance_variable_get(:"@#{relationship}") if instance_variable_get(:"@#{relationship}")
      instance_variable_set(:"@#{relationship}", query_service.find_references_by(resource: resource, property: property).to_a)
    end
    define_method "decorated_#{relationship}" do
      return instance_variable_get(:"@decorated_#{relationship}") if instance_variable_get(:"@decorated_#{relationship}")
      instance_variable_set(:"@decorated_#{relationship}", __send__(relationship).map(&:decorate))
    end
    define_singular_relation(relationship) if singular
  end

  # Creates relationship methods `relationship` and `decorated_relationship`
  # which queries for all records which reference this record by a given property.
  #
  # @param relationship [Symbol] Name of the relationship, will become the
  #   method name created.
  # @param property [Symbol] Name of the property which stores IDs for the
  #   relationship.
  # @param singular [Boolean] Creates singular methods as well if true (IE
  #   ephemera_project if relationship is ephemera_projects)
  # @param model [Class] Model to filter results by.
  def self.inverse_relationship_by_property(relationship, property:, singular: false, model: nil)
    define_method relationship do
      return instance_variable_get(:"@#{relationship}") if instance_variable_get(:"@#{relationship}")
      output = query_service.find_inverse_references_by(resource: resource, property: property).to_a
      output = output.select { |x| x.is_a?(model) } if model
      instance_variable_set(:"@#{relationship}", output)
    end
    define_method "decorated_#{relationship}" do
      return instance_variable_get(:"@decorated_#{relationship}") if instance_variable_get(:"@decorated_#{relationship}")
      instance_variable_set(:"@decorated_#{relationship}", __send__(relationship).map(&:decorate))
    end
    define_singular_relation(relationship) if singular
  end

  def self.define_singular_relation(relationship)
    singular_name = relationship.to_s.singularize
    define_method singular_name do
      __send__(relationship).first
    end
    define_method "decorated_#{singular_name}" do
      return instance_variable_get(:"@decorated_#{singular_name}") if instance_variable_get(:"@decorated_#{singular_name}")
      instance_variable_set(:"@decorated_#{singular_name}", __send__(singular_name).try(:decorate))
    end
  end

  def self.member_relationship(relationship, model: nil)
    define_method relationship do
      return instance_variable_get(:"@#{relationship}") if instance_variable_get(:"@#{relationship}")
      instance_variable_set(:"@#{relationship}", query_service.find_members(resource: resource, model: model).to_a)
    end
    define_method "decorated_#{relationship}" do
      return instance_variable_get(:"@decorated_#{relationship}") if instance_variable_get(:"@decorated_#{relationship}")
      instance_variable_set(:"@decorated_#{relationship}", __send__(relationship).map(&:decorate))
    end
  end

  attr_reader :resource
  delegate :query_service, to: :metadata_adapter
  def initialize(resource:)
    @resource = resource
  end

  def metadata_adapter
    @metadata_adapter ||= Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
