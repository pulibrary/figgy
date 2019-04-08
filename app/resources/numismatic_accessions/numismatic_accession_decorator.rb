# frozen_string_literal: true
class NumismaticAccessionDecorator < Valkyrie::ResourceDecorator
  display :accession_number,
          :date,
          :items_number,
          :type,
          :cost,
          :account,
          :person,
          :firm,
          :note,
          :private_note,
          :numismatic_citations

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

  def numismatic_citations
    numismatic_citation.map { |c| c.decorate.title }
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def label
    "#{accession_number}: #{date} #{type} #{from_label} #{cost_label}"
  end

  def from_label
    divider = "/" if person && firm
    "#{person}#{divider}#{firm}"
  end

  def cost_label
    "" unless cost
    "(#{cost})"
  end
end
