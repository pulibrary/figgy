# frozen_string_literal: true
class PlumChangeSetPersister
  class DeleteFixityCheck
    attr_reader :change_set_persister, :change_set
    delegate :resource, to: :change_set
    delegate :query_service, to: :change_set_persister

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless resource.respond_to? :original_file
      resource.original_file.file_identifiers.each do |file_id| 
        query_service.custom_queries.find_by_string_property(property: :file_id, value: file_id).
          select{ |obj| obj.class == FixityCheck }.each do |fc|
          change_set_persister.delete(change_set: FixityCheckChangeSet.new(fc))
        end
      end
    end
  end
end
