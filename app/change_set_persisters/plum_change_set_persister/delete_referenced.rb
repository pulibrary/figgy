# frozen_string_literal: true
class PlumChangeSetPersister
  class DeleteReferenced
    class Factory
      attr_reader :property
      def initialize(property:)
        @property = property
      end

      def new(change_set_persister:, change_set:, post_save_resource: nil)
        DeleteReferenced.new(change_set_persister: change_set_persister,
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
        cs = DynamicChangeSet.new(resource)
        change_set_persister.delete(change_set: cs)
      end
    end

    def resources
      query_service.find_inverse_references_by(resource: change_set.resource, property: property)
    end
  end
end
