# frozen_string_literal: true

module CDL
  class AutomaticCompleter
    def self.run
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        new(change_set_persister: buffered_change_set_persister).run
      end
    end

    def self.change_set_persister
      ChangeSetPersister.default
    end

    delegate :metadata_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    attr_reader :change_set_persister
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def run
      resources = []
      draft_cdl_resources.each do |draft_resource|
        next unless ready_for_completion?(draft_resource)
        change_set = ChangeSet.for(draft_resource)
        change_set.validate(state: "complete")
        resource = change_set_persister.save(change_set: change_set)
        resources += [resource]
      end
      notify(resources: resources) if resources.present?
    end

    def notify(resources:)
      CDL::CompleteMailer.with(resource_ids: resources.map(&:id).map(&:to_s)).resources_completed.deliver_later
    end

    def draft_cdl_resources
      query_service.custom_queries.find_by_property(
        property: :metadata,
        value: { state: "draft", change_set: "CDL::Resource" },
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
        # The first member is the PDF itself, so do member_count - 1.
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

      def pdf_page_count
        first_member.primary_file.page_count
      end
    end
  end
end
