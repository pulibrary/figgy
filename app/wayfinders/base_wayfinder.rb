# frozen_string_literal: true
# Wayfinders are classes which manage navigating relationships between IDs
# stored on a Valkyrie::Resource to their associated Valkyrie::Resources.
#
# These wayfinders are most commonly accessed via
# {Valkyrie::ResourceDecorator#wayfinder}, however they can also be instantiated
# stand-alone in a controller or other context via {Wayfinder.for}.
#
# @example Instantiate a wayfinder and get all members.
#   Wayfinder.for(parent).members # => [#<ScannedResource>]
#
# @example Define a wayfinder for a class which has FileSets.
#   class ExampleWayfinder < BaseWayfinder
#     relationship_by_property :file_sets, property: :member_ids, model: FileSet
#   end
#   ExampleWayfinder.new(resource).file_sets # => [#<FileSet>]
#   ExampleWayfinder.new(resource).decorated_file_sets # => [#<FileSetDecorator>]
#
#
# @see Wayfinder
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

  # Collections are only assigned at the MVW level, but permissions for volumes
  # need to see if a user has permission for a restricted collection. To do that
  # it needs its parents collections if it has one.
  def self_or_parent_collections
    if try(:parent).present?
      Wayfinder.for(parent).try(:collections)
    else
      try(:collections) || []
    end
  end

  # Define a preservation_objects relationship for all resources
  inverse_relationship_by_property :preservation_objects, property: :preserved_object_id, singular: true, model: PreservationObject

  def resource_charge_list
    @resource_charge_list ||= query_service.custom_queries.find_by_property(property: :resource_id, value: resource.id, model: CDL::ResourceChargeList).first
  end

  def metadata_adapter
    @metadata_adapter ||= Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def deep_failed_local_fixity_count
    @deep_failed_local_fixity_count ||= deep_fixity_count(fixity_status: Event::FAILURE)
  end

  def deep_succeeded_local_fixity_count
    @deep_succeeded_local_fixity_count ||= deep_fixity_count(fixity_status: Event::SUCCESS)
  end

  def deep_failed_cloud_fixity_count
    @deep_failed_cloud_fixity_count ||= query_service.custom_queries.find_deep_failed_cloud_fixity_count(
      resource: resource
    )
  end

  def deep_succeeded_cloud_fixity_count
    @deep_succeeded_cloud_fixity_count ||=
      query_service.custom_queries.find_deep_preservation_object_count(resource: resource) -
      deep_failed_cloud_fixity_count
  end

  def deep_file_sets
    @deep_file_sets ||= query_service.custom_queries.find_deep_children_with_property(
      resource: resource,
      model: FileSet,
      property: :file_metadata,
      value: nil
    )
  end

  def deep_file_set_count
    @deep_file_set_count ||= query_service.custom_queries.find_deep_children_with_property(
      resource: resource,
      model: FileSet,
      property: :file_metadata,
      value: nil,
      count: true
    )
  end

  def current_cloud_fixity_event
    @current_cloud_fixity_event ||= query_service.custom_queries.find_by_property(
      property: :metadata,
      value: {
        resource_id: Valkyrie::ID.new(resource.id),
        type: "cloud_fixity",
        current: true
      },
      model: Event
    )&.first
  end

  def current_local_fixity_event
    @current_local_fixity_event ||= query_service.custom_queries.find_by_property(
      property: :metadata,
      value: {
        resource_id: Valkyrie::ID.new(resource.id),
        type: "local_fixity",
        current: true
      },
      model: Event
    )&.first
  end

  # Convenience accessor for loading the first member object, without having to
  # load all of the other members.
  def first_member
    return unless resource.try(:member_ids)&.first
    @first_member ||= query_service.find_by(id: resource.member_ids.first)
  end

  # Special case of loading the first member, but suppressing it unless it's a
  # pdf file.
  def source_pdf
    first_member if first_member.try(:mime_type) == ["application/pdf"]
  end

  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  private

    def deep_fixity_count(fixity_status:)
      query_service.custom_queries.deep_local_fixity_count(
        resource: resource,
        status: fixity_status
      )
    end
end
