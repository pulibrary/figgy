# frozen_string_literal: true
class FileSetChangeSet < ChangeSet
  self.fields = [:title]
  property :optimistic_lock_token,
           multiple: true,
           required: true,
           type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)
  property :files, virtual: true, multiple: true, required: false
  property :viewing_hint, multiple: false, required: false
  property :hocr_content, multiple: false, required: false
  property :ocr_content, multiple: false, required: false
  property :read_groups, multiple: true, required: false
  delegate :thumbnail_id, to: :model

  def primary_terms
    [:title]
  end

  def preserve?
    return false unless persisted?
    parent = Wayfinder.for(self).parent
    return false unless parent
    ChangeSet.for(parent).try(:preserve?) && Wayfinder.for(parent).try(:preservation_objects).present?
  end
end
