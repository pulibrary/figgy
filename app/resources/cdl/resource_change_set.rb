# frozen_string_literal: true

module CDL
  class ResourceChangeSet < ChangeSet
    apply_workflow(DraftCompleteWorkflow)
    core_resource(change_set: "CDL::Resource", remote_metadata: true)
    enable_order_manager
    enable_claiming
    property :ocr_language, multiple: true, require: false, default: []
    property :downloadable, multiple: false, require: true, default: "none"
    property :portion_note, multiple: false, required: false
    property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    property :rights_statement, multiple: false, required: true, default: RightsStatements.in_copyright, type: ::Types::URI
    property :depositor, multiple: false, require: false

    # Don't preserve copyrighted material.
    def preserve?
      false
    end

    def primary_terms
      [
        :title,
        :source_metadata_identifier,
        :member_of_collection_ids,
        :rights_statement,
        :rights_note,
        :downloadable,
        :ocr_language,
        :portion_note,
        :append_id,
        :change_set
      ]
    end
  end
end
