# frozen_string_literal: true
#
# A persistence handler for removing Valkyrie::StorageAdapter::File members objects from Resource
class PlumChangeSetPersister
  class CleanupDerivatives
    # Access the ChangeSetPersister and ChangeSet attributes
    attr_reader :change_set_persister, :change_set
    # Access the resource within the ChangeSet attribute
    # @return [Valkyrie::Resource]
    delegate :resource, to: :change_set
    # The initializer
    # @param change_set_persist [ChangeSetPersister] the change set persister
    # @param change_set [ChangeSet] the change set for a resource
    def initialize(change_set_persister:, change_set:)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    # Run the persistence handler
    # Iterates through each FileSet for the resource being updated, and deletes its derivative File member
    def run
      return unless decorated_resource.respond_to?(:file_sets) && file_sets.present?
      file_sets.each do |file_set|
        next unless file_set.instance_of?(FileSet)
        ::CleanupDerivativesJob.perform_later(file_set.id.to_s)
      end
    end

    private

      # Access the decorated resource
      # @return [Draper::Decorator]
      def decorated_resource
        @decorated_resource ||= resource.decorate
      end

      # Access the FileSets for the resource
      # @return [Array<FileSet>, nil] return an array of FileSets or nil
      def file_sets
        @file_sets ||= decorated_resource.try(:file_sets)
      end
  end
end
