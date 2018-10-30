# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :department,
          :size,
          :die_axis,
          :weight,
          :references,
          :visibility,
          :accession,
          :analysis,
          :counter_stamp,
          :find,
          :find_date,
          :holding_location,
          :loan,
          :object_type,
          :place,
          :private_note,
          :provenance,
          :technique

  delegate :members, :decorated_file_sets, :decorated_parent, to: :wayfinder

  def ark_mintable_state?
    false
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
