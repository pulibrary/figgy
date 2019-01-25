# frozen_string_literal: true
class DateRangeDecorator < Valkyrie::ResourceDecorator
  def range_string
    return unless start && self.end
    "#{approximate ? 'approximately ' : ''}#{start.first}-#{self.end.first}"
  end
end
