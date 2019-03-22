# frozen_string_literal: true
class LetterChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  core_resource(change_set: "letter")
  enable_order_manager
  enable_pdf_support

  collection :sender, multiple: true, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_property, default: []
  collection :recipient, multiple: true, required: false, form: NameWithPlaceChangeSet, populator: :populate_nested_property, default: []
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
    schema["recipient"][:nested].new(model.class.schema[:recipient][[{}]].first)
  end

  def build_sender
    schema["sender"][:nested].new(model.class.schema[:sender][[{}]].first)
  end
end
