# frozen_string_literal: true
class FileSetChangeSet < ChangeSet
  self.fields = [:title]
  property :files, virtual: true, multiple: true, required: false
  property :viewing_hint, multiple: false, required: false
  property :hocr_content, multiple: false, required: false
  property :ocr_content, multiple: false, required: false
  property :read_groups, multiple: true, required: false
  property :file_metadata
  property :service_targets, multiple: true, required: false

  delegate :thumbnail_id, to: :model

  def primary_terms
    [
      :title,
      :service_targets
    ]
  end

  def preserve?
    return false unless persisted?
    parent = Wayfinder.for(self).parent
    return false unless parent
    ChangeSet.for(parent).try(:preserve?) && Wayfinder.for(parent).try(:preservation_objects).present?
  end
end
