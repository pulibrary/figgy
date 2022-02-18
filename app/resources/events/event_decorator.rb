# frozen_string_literal: true

class EventDecorator < Valkyrie::ResourceDecorator
  def affected_resource
    wayfinder.decorated_affected_resource
  end

  def affected_child
    wayfinder.decorated_affected_child
  end
end
