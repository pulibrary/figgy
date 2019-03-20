# frozen_string_literal: true
class LetterChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  core_resource(change_set: "letter")
  enable_order_manager
  enable_pdf_support

  property :sender, multiple: false, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_property
  property :recipient, multiple: false, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_property

  def primary_terms
    feature_terms.dup.insert(
      2,
      [
        :sender,
        :recipient,
        :member_of_collection_ids
      ]
    ).flatten
  end
end
