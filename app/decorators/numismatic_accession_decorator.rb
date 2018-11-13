# frozen_string_literal: true
class NumismaticAccessionDecorator < Valkyrie::ResourceDecorator
  display :date,
          :person,
          :firm,
          :accession_number,
          :type,
          :cost,
          :account,
          :note,
          :private_note

  delegate :members, to: :wayfinder

  def date
    Array.wrap(super).first
  end

  def person
    Array.wrap(super).first
  end

  def firm
    Array.wrap(super).first
  end

  def type
    Array.wrap(super).first
  end

  def cost
    Array.wrap(super).first
  end

  def account
    Array.wrap(super).first
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
