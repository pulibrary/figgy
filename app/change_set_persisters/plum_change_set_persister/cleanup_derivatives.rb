# frozen_string_literal: true
class PlumChangeSetPersister
  class CleanupDerivatives
    attr_reader :change_set_persister, :change_set
    delegate :resource, to: :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    def run
      return unless decorated_resource.respond_to?(:file_sets) && file_sets.present?
      file_sets.each do |file_set|
        next unless file_set.instance_of?(FileSet)
        ::CleanupDerivativesJob.perform_later(file_set.id.to_s)
      end
    end

    private

      def decorated_resource
        @decorated_resource ||= resource.decorate
      end

      def file_sets
        @file_sets ||= decorated_resource.file_sets
      end
  end
end
