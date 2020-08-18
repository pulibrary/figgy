# frozen_string_literal: true

module CDL
  class AutomaticApprover
    def self.run
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        new(change_set_persister: buffered_change_set_persister).run
      end
    end

    def self.change_set_persister
      ScannedResourcesController.change_set_persister
    end

    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    attr_reader :change_set_persister
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def run
      pending_cdl_resources.each do |pending_resource|
        next unless ready_for_completion?(pending_resource)
        change_set = ChangeSet.for(pending_resource)
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)
      end
    end

    def pending_cdl_resources
      query_service.custom_queries.find_by_property(
        property: :metadata,
        value: { state: "pending", change_set: "CDL::Resource" },
        model: ScannedResource,
        lazy: true
      )
    end

    def ready_for_completion?(resource)
      CompletionEligibility.new(change_set_persister: change_set_persister, resource: resource).eligible?
    end

    class CompletionEligibility
      delegate :metadata_adapter, to: :change_set_persister
      delegate :query_service, to: :metadata_adapter
      attr_reader :change_set_persister, :resource
      def initialize(change_set_persister:, resource:)
        @change_set_persister = change_set_persister
        @resource = resource
      end

      def eligible?
        all_processed? && pages_match? && manifest_generates?
      end

      # All child file sets are processed.
      def all_processed?
        query_service.custom_queries.find_deep_children_with_property(resource: resource, model: FileSet, property: :processing_status, value: "in process", count: true).zero?
      end

      def pages_match?
        first_member.mime_type.include?("application/pdf")
        pdf_page_count == resource.member_ids.size - 1
      end

      def manifest_generates?
        ManifestBuilder.new(resource).build
        true
      rescue
        false
      end

      def first_member
        @first_member ||= query_service.find_by(id: resource.member_ids.first)
      end

      def pdf_file_path
        @pdf_file_path ||= Valkyrie::StorageAdapter.find_by(id: first_member.primary_file.file_identifiers.first).disk_path
      end

      def pdf_page_count
        @pdf_page_count ||= Vips::Image.pdfload(pdf_file_path.to_s, access: :sequential, memory: true).get_value("pdf-n_pages")
      end
    end
  end
end
