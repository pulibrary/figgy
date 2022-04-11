# frozen_string_literal: true
class EventWayfinder < BaseWayfinder
  relationship_by_property :affected_resources, property: :resource_id, singular: true

  def affected_children
    return [] if affected_resource.nil? || resource.child_property.nil?
    results = affected_resource.send(resource.child_property.to_sym)
    Array.wrap(results)
  end

  def decorated_affected_children
    affected_children.map(&:decorate)
  end

  def affected_child
    affected_children.first
  end

  def decorated_affected_child
    decorated_affected_children.first
  end
end
