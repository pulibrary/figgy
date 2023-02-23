# frozen_string_literal: true

class ChangeSetPersister
  class CleanupPDFDerivatives
    attr_reader :resource, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @resource = change_set.resource
    end

    def run
      return unless resource.is_a?(FileSet)
      return if resource.file_metadata.select(&:pdf?).blank?
      PDFDerivativeService.new(id: resource.id, change_set_persister: @change_set_persister).cleanup_derivatives
    end
  end
end
