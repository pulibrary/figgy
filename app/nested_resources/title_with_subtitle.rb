# frozen_string_literal: true

class TitleWithSubtitle < Valkyrie::Resource
  attribute :title, Valkyrie::Types::Anything
  attribute :subtitle, Valkyrie::Types::Anything

  def to_s
    "#{title}: #{subtitle}"
  end
end
