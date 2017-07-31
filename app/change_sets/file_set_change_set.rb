# frozen_string_literal: true
class FileSetChangeSet < Valkyrie::ChangeSet
  self.fields = [:title]
  property :files, virtual: true, multiple: true, required: false

  def primary_terms
    [:title]
  end
end
