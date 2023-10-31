# frozen_string_literal: true
class CoinIndexer
  delegate :query_service, to: :metadata_adapter
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.is_a?(Numismatics::Coin)
    return {} unless parent
    linked_and_nested_coin_fields.merge(parent_fields)
  end

  def parent_attributes
    attributes = parent.attributes.dup.merge(linked_and_nested_parent_attributes)
    attributes.delete_if { |k, v| parent_keys_suppress.include?(k) || v.blank? }
  end

  def linked_and_nested_parent_attributes
    {
      artist: decorated_issue.artists,
      citation: decorated_issue.citations,
      subject: decorated_issue.subjects,
      place: decorated_issue.rendered_place,
      obverse_attribute: decorated_issue.obverse_attributes,
      reverse_attribute: decorated_issue.reverse_attributes,
      ruler: decorated_issue.rulers,
      master: decorated_issue.master,
      monograms: decorated_issue.monograms
    }
  end

  def parent_fields
    parent_attributes.map { |k, v| ["issue_#{k}_tesim", Array.wrap(v).map(&:to_s)] }.to_h
  end

  def linked_and_nested_coin_attributes
    {
      accession: decorated_coin.rendered_accession,
      citation: decorated_coin.citations,
      find_place: decorated_coin.find_place,
      provenance: decorated_coin.provenance
    }
  end

  def linked_and_nested_coin_fields
    linked_and_nested_coin_attributes.map { |k, v| ["#{k}_tesim", Array.wrap(v).map(&:to_s)] }.to_h
  end

  def parent_keys_suppress
    [
      :id, :internal_resource, :created_at, :updated_at, :new_record, :read_groups, :read_users, :edit_users,
      :edit_groups, :member_ids, :member_of_collection_ids, :optimistic_lock_token, :state, :thumbnail_id,
      :visibility, :workflow_note, :pending_uploads, :start_canvas, :viewing_direction, :viewing_hint,
      :numismatic_artist, :numismatic_citation, :numismatic_subject
    ]
  end

  def parent
    @parent ||= query_service.find_parents(resource: resource).first
  end

  def decorated_coin
    @decorated_coin ||= resource.decorate
  end

  def decorated_issue
    @decorated_issue ||= parent.decorate
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
