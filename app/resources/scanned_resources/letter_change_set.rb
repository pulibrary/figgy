# frozen_string_literal: true
class LetterChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  core_resource(change_set: "letter")
  enable_order_manager
  enable_pdf_support

  property :sender, multiple: false, required: false, form: NameWithPlaceChangeSet, populator: :populate_name_with_place
  property :recipient, multiple: false, required: false, form: NameWithPlaceChangeSet, populator: :populate_name_with_place

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

  def prepopulate!(_args = {})
    self.sender ||= NameWithPlace.new
    self.recipient ||= NameWithPlace.new
    super
  end

  def populate_name_with_place(fragment:, as:, **)
    if fragment.values.select(&:present?).blank?
      send(:"#{as}=", nil)
      return skip!
    end
    send(:"#{as}=", NameWithPlace.new(fragment))
  end
end
