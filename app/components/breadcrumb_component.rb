# frozen_string_literal: true
class BreadcrumbComponent < ViewComponent::Base
  renders_one :root_breadcrumb
  attr_reader :decorated_resource
  def initialize(decorated_resource:)
    @decorated_resource = decorated_resource
  end

  def breadcrumb_hierarchy
    decorated_resource.try(:breadcrumb_hierarchy) ||
      deep_parents(decorated_resource.object)
  end

  def deep_parents(resource, accumulator = [])
    parents = Wayfinder.for(resource).parents
    return accumulator if parents.blank?
    accumulator = parents.map(&:decorate) + accumulator
    deep_parents(accumulator.first, accumulator)
  end
end
