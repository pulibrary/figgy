# frozen_string_literal: true
class ViewingDirectionValidator < ActiveModel::Validator
  delegate :validate, to: :inclusivity_validator

  private

    def inclusivity_validator
      @inclusivity_validator ||= ActiveModel::Validations::InclusionValidator.new(
        attributes: :viewing_direction,
        in: valid_viewing_directions,
        allow_blank: true
      )
    end

    def valid_viewing_directions
      [
        "left-to-right",
        "right-to-left",
        "top-to-bottom",
        "bottom-to-top"
      ].map { |x| Array.wrap(x) }
    end
end
