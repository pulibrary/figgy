# frozen_string_literal: true
class FileSetChangeSet < Valkyrie::ChangeSet
  self.fields = [:title]

  def primary_terms
    [:title]
  end
end
