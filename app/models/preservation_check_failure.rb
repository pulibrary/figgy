class PreservationCheckFailure < ApplicationRecord
  belongs_to :preservation_audit

  def details_hash
    {
      id: resource_id,
      resource_class: resource&.class,
      created_at: resource&.created_at,
      updated_at: resource&.updated_at,
      mime_type: resource&.try(:mime_type),
      preservation_object?: preservation_object.present?,
      metadata_preserved?: preservation_object&.metadata_node.present?,
      m_preservation_file_exists?: md_checker&.preservation_file_exists?,
      m_preservation_ids_match?: md_checker&.preservation_ids_match?,
      m_recorded_versions_match?: md_checker&.recorded_versions_match?,
      m_preserved_checksums_match?: md_checker&.preserved_file_checksums_match?,
      binaries_preserved?: preservation_object&.binary_nodes.present?,
      preservation_ids_match?: bin_checkers&.map(&:preservation_ids_match?)&.map(&:present?),
      recorded_checksums_match?: bin_checkers&.map(&:recorded_checksums_match?)
    }
  end

  private

    def resource
      @resource ||= begin
                      query_service.find_by(id: Valkyrie::ID.new(resource_id))
                    rescue Valkyrie::Persistence::ObjectNotFoundError
                      nil
                    end
    end

    def wayfinder
      @wayfinder ||= Wayfinder.for(resource)
    end

    def preservation_object
      @preservation_object ||= wayfinder.preservation_object
    rescue ArgumentError
      # if there's no resource the preservation object query errors
      nil
    end

    def md_checker
      # pull first checker because there's always only one; it's just wrapped in an array for consistency with the binary checkers
      preservation_object && Preserver::PreservationChecker.metadata_for(resource: resource, preservation_object: preservation_object).first
    end

    def bin_checkers
      preservation_object && Preserver::PreservationChecker.binaries_for(resource: resource, preservation_object: preservation_object)
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
