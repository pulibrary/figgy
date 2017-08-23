# frozen_string_literal: true
class FileSetChangeSet < Valkyrie::ChangeSet
  self.fields = [:title]
  property :files, virtual: true, multiple: true, required: false
  property :viewing_hint, multiple: false, required: false
  delegate :thumbnail_id, to: :model

  def primary_terms
    [:title]
  end
end
