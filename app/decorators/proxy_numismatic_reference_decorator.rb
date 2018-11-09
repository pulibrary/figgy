# frozen_string_literal: true
class ProxyNumismaticReferenceDecorator < Valkyrie::ResourceDecorator
  def to_s
    "#{numismatic_reference_short_title}, #{part} #{number}"
  end

  def numismatic_reference_short_title
    wayfinder.numismatic_reference&.short_title&.first
  end

  def number
    Array.wrap(super).first
  end

  def part
    Array.wrap(super).first
  end
end
