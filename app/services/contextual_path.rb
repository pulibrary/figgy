# frozen_string_literal: true
class ContextualPath
  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::PolymorphicRoutes
  attr_reader :child, :parent_id
  def initialize(child:, parent_id: nil)
    @child = child
    @parent_id = parent_id
  end

  def show
    polymorphic_path([:solr_document], id: child.id.to_s)
  end

  def file_manager
    polymorphic_path([:file_manager, child])
  end

  def to_resource
    nil
  end
end
