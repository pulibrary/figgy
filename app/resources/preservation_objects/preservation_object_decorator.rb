# frozen_string_literal: true
class PreservationObjectDecorator < Valkyrie::ResourceDecorator
  delegate :events, to: :wayfinder

  def preserved_resources
    wayfinder.decorated_preserved_resources
  end

  def preserved_resource
    wayfinder.decorated_preserved_resource
  end
end
