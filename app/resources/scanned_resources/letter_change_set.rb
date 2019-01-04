# frozen_string_literal: true
class LetterChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  core_resource(change_set: "letter")
  enable_order_manager
  enable_pdf_support

  collection :sender, multiple: true, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_collection, default: []
  collection :recipient, multiple: true, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_collection, default: []
  self.feature_terms += [:member_of_collection_ids]

  def primary_terms
    {
      "" => feature_terms,
      "Sender" => [
        :sender
      ],
      "Recipient" => [
        :recipient
      ]
    }
  end

  def build_recipient
    schema["recipient"][:nested].new(model_type_for(property: :recipient)[[{}]].first)
  end

  def build_sender
    schema["sender"][:nested].new(model_type_for(property: :sender)[[{}]].first)
  end
end
