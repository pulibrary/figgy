# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :coin_number,
          :weight,
          :holding_location,
          :size,
          :die_axis,
          :technique,
          :counter_stamp,
          :analysis,
          :public_note,
          :private_note,
          :find_place,
          :find_number,
          :find_date,
          :find_locus,
          :find_feature,
          :find_description,
          :holding_location,
          :numismatic_collection,
          :accession_number,
          :provenance,
          :loan,
          :replaces,
          :visibility,
          :append_id

  delegate :members, :decorated_file_sets, :decorated_parent, :decorated_numismatic_citations, :decorated_numismatic_artists, :accession, to: :wayfinder

  def ark_mintable_state?
    false
  end

  delegate :id, :label, to: :accession, prefix: true

  def citations
    decorated_numismatic_citations.map(&:title)
  end

  def artists
    decorated_numismatic_artists.map(&:title)
  end

  def pub_created_display
    [decorated_parent.ruler, decorated_parent.denomination, decorated_parent.workshop].join(", ")
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def orangelight_id
    "coin-#{coin_number}"
  end

  def state
    super.first
  end
end
