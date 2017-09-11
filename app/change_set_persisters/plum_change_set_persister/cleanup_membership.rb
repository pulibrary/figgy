# frozen_string_literal: true
class PlumChangeSetPersister
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
    PlumChangeSetPersister.register_handler(:before_delete, Factory.new(property: :member_of_collection_ids))
    PlumChangeSetPersister.register_handler(:before_delete, Factory.new(property: :member_ids))
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
        persister.save(resource: resource)
      end
    end

    def resources
      query_service.find_inverse_references_by(resource: change_set.resource, property: property)
    end
  end
end
