# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :department,
          :size,
          :die_axis,
          :weight,
          :donor,
          :deposit_of,
          :seller,
          :references,
          :visibility

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
