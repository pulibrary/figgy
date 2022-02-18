# frozen_string_literal: true

class PreservationObjectChangeSet < ChangeSet
  def preserve?
    false
  end
end
