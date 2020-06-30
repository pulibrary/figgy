# frozen_string_literal: true

module CDL
  class ChargedItem < Valkyrie::Resource
    attribute :item_id, Valkyrie::Types::String
    attribute :netid, Valkyrie::Types::String
    attribute :expiration_time, Valkyrie::Types::Time
  end
end
