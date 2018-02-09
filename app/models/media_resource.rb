# frozen_string_literal: true
# Generated with `rails generate valkyrie:model MediaResource`
class MediaResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :state
end
