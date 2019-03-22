# frozen_string_literal: true
class NameWithPlaceChangeSet < ChangeSet
  property :name
  property :place
  property :_destroy, virtual: true

  def new_record?
    false
  end

  def marked_for_destruction?
    false
  end
end
