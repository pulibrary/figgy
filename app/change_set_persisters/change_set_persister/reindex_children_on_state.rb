# frozen_string_literal: true

class ChangeSetPersister
  class ReindexChildrenOnState
    class Factory
      attr_reader :model, :state
      def initialize(model:, state:)
        @model = model
        @state = state
      end

      def new(change_set_persister:, change_set:, post_save_resource: nil)
        ReindexChildrenOnState.new(change_set_persister: change_set_persister,
          change_set: change_set,
          post_save_resource: post_save_resource,
          model: model,
          state: state)
      end
    end
    attr_reader :change_set_persister, :change_set, :model, :state, :post_save_resource
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, model:, state:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @model = model
      @state = state
      @post_save_resource = post_save_resource
    end

    def run
      return unless post_save_resource.is_a?(model) && post_save_resource.state == Array.wrap(state)
      children.each do |resource|
        cs = ChangeSet.for(resource)
        change_set_persister.save(change_set: cs)
      end
    end

    def children
      @children ||= query_service.find_members(resource: post_save_resource)
    end
  end
end
