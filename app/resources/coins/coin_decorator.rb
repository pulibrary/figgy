# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :accession,
          :analysis,
          :counter_stamp,
          :department,
          :die_axis,
          :find_date,
          :find_description,
          :find_feature,
          :find_locus,
          :find_number,
          :find_place,
          :holding_location,
          :loan,
          :object_type,
          :place,
          :private_note,
          :provenance,
          :replaces,
          :size,
          :technique,
          :visibility,
          :weight

  delegate :members, :decorated_file_sets, :decorated_parent, :decorated_numismatic_citations, to: :wayfinder

  def ark_mintable_state?
    false
  end

  def citations
    decorated_numismatic_citations.map(&:title)
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def state
    super.first
  end
end
