# frozen_string_literal: true
class NumismaticPlaceChangeSet < ChangeSet
  property :city
  property :state
  property :region
  property :_destroy, virtual: true

  def new_record?
    false
  end

  def marked_for_destruction?
    false
  end
end
