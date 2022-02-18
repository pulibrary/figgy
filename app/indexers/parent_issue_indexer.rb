# frozen_string_literal: true

class ParentIssueIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(Numismatics::Coin)
    return {} unless parents.first

    parent_attributes.map { |k, v| ["issue_#{k}_tesim", Array.wrap(v).map(&:to_s)] }.to_h
  end

  def parent_attributes
    parents.first.attributes.dup.delete_if { |k, v| parent_keys_suppress.include?(k) || v.blank? }
  end

  def parent_keys_suppress
    [:id, :internal_resource, :created_at, :updated_at, :new_record, :read_groups, :read_users, :edit_users,
      :edit_groups, :member_ids, :member_of_collection_ids, :state, :thumbnail_id, :visibility, :workflow_note,
      :pending_uploads, :start_canvas, :viewing_direction, :viewing_hint]
  end

  def parents
    @parents ||= query_service.find_parents(resource: resource)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
