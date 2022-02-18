# frozen_string_literal: true

class ChangeSetPersister
  class CleanupMembership
    class Factory
      attr_reader :property
      def initialize(property:)
        @property = property
      end

      def new(change_set_persister:, change_set:, post_save_resource: nil)
        CleanupMembership.new(change_set_persister: change_set_persister,
          change_set: change_set,
          post_save_resource: post_save_resource,
          property: property)
      end
    end
    attr_reader :change_set_persister, :change_set, :post_save_resource, :property
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, property:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
      @property = property
    end

    def run
      resources.each do |resource|
        resource.__send__("#{property}=", resource.__send__(property) - [change_set.id])
        if resource.respond_to?(:thumbnail_id) && change_set.resource.decorate.respond_to?(:file_sets)
          file_set_ids = change_set.resource.decorate.file_sets.map(&:id)
          intersection = Array.wrap(resource.thumbnail_id) & file_set_ids
          resource.thumbnail_id = resource.thumbnail_id - file_set_ids unless intersection.empty?
        end
        persister.save(resource: resource)
      end
    end

    def resources
      query_service.find_inverse_references_by(resource: change_set.resource, property: property)
    end
  end
end
