# frozen_string_literal: true
class LetterChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  core_resource(change_set: "letter")
  enable_order_manager
  enable_pdf_support

  collection :sender, multiple: true, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_property, default: []
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

  def build_sender
    schema["sender"][:nested].new(model.class.schema[:sender][[{}]].first)
  end
end
