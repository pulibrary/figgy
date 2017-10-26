# frozen_string_literal: true
class PlumChangeSetPersister
  class DeleteMembers
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      resources.each do |resource|
        cs = DynamicChangeSet.new(resource)
        change_set_persister.delete(change_set: cs)
      end
    end

    def resources
      return [] unless change_set.resource.respond_to? :member_ids
      query_service.find_references_by(resource: change_set.resource, property: :member_ids).reject { |member| member.is_a? FileSet }
    end
  end
end
