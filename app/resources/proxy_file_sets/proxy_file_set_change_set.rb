# frozen_string_literal: true

class ProxyFileSetChangeSet < ChangeSet
  delegate :human_readable_type, to: :resource

  include VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :read_groups, multiple: true, required: false

  property :label, multiple: true, required: true, default: []
  property :proxied_file_id, multiple: false, required: true
  property :local_identifier, multiple: true, required: false, default: []

  validates :visibility, :label, :proxied_file_id, presence: true

  def primary_terms
    [
      :label
    ]
  end
end
