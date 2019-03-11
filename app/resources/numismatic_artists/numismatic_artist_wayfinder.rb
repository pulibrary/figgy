# frozen_string_literal: true
class NumismaticArtistWayfinder < BaseWayfinder
  inverse_relationship_by_property :numismatic_artist_parents, singular: true, property: :numismatic_artist_ids
end
