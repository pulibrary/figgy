# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :coin_number,
          :holding_location,
          :counter_stamp,
          :analysis,
          :public_note,
          :private_note,
          :place,
          :find_date,
          :find_feature,
          :find_locus,
          :find_description,
          :images,
          :accession_number,
          :department,
          :provenance,
          :die_axis,
          :append_id,
          :find,
          :loan,
          :object_type,
          :size,
          :technique,
          :weight,
          :find_number,
          :find_place,
          :replaces,
          :visibility

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
