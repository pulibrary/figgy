# frozen_string_literal: true
module Types::Event
  include Types::BaseInterface
  description "An event modifying a resource in the system."

  field :id, String, null: true
  field :messages, [String], null: true
  field :modified_resources, [Types::Resource], null: true

  def modified_resources
    @modified_resources ||= Wayfinder.for(object).modified_resources
  end
end
