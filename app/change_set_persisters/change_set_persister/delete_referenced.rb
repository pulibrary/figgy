# frozen_string_literal: true
class ChangeSetPersister
  class DeleteReferenced
    class Factory
      attr_reader :property, :parent_model
      def initialize(property:, parent_model: nil)
        @property = property
        @parent_model = parent_model
      end

      def new(change_set_persister:, change_set:)
        DeleteReferenced.new(change_set_persister: change_set_persister,
                             change_set: change_set,
                             property: property,
                             parent_model: parent_model)
      end
    end
    attr_reader :change_set_persister, :change_set, :property, :parent_model
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, property:, parent_model:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @property = property
      @parent_model = parent_model
    end

    def run
      return if parent_model && !change_set.resource.is_a?(parent_model)
      resources.each do |resource|
        cs = ChangeSet.for(resource)
        change_set_persister.delete(change_set: cs)
      end
    end

    def resources
      query_service.find_inverse_references_by(resource: change_set.resource, property: property)
    end
  end
end
